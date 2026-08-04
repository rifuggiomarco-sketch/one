import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/mesh_packet.dart';

typedef PacketHandler = void Function(MeshPacket packet);

/// Runs this phone as one node of a small flooding BLE mesh: it
/// continuously scans for other nodes' location packets, hands every
/// packet it sees to [onPacket] (the caller decides which senders are
/// bonded friends), and relays *everyone's* packets - bonded or not -
/// for a few hops so a friend can be found even when they're out of
/// direct Bluetooth range, as long as other phones running the app are
/// scattered in between.
///
/// This trades true multi-hop reliability (which the dedicated mesh
/// necklaces get from purpose-built long-range radios) for something
/// that runs on stock phone hardware: the whole packet rides inside a
/// BLE advertisement, so no pairing or GATT connection is needed
/// between hops - but only one payload can be on air per advertising
/// slot, so each node round-robins between its own packet and whatever
/// it's currently relaying.
///
/// Advertising manufacturer data is Android-only (iOS's CoreBluetooth
/// peripheral mode doesn't expose it), so on iOS this device can still
/// receive and display friends' positions relayed by Android phones
/// nearby, but can't broadcast its own or relay for others.
class MeshService {
  MeshService({required this.myShortId, required this.onPacket});

  final int myShortId;
  final PacketHandler onPacket;

  static const _maxTtl = 6;
  static const _relayExpiry = Duration(seconds: 12);
  static const _advertiseSlot = Duration(seconds: 1);
  static const _dedupeWindow = Duration(seconds: 30);

  /// Custom (unregistered) service UUID identifying rave_finder packets;
  /// only used to help other rave_finder devices notice us, the actual
  /// payload always travels in manufacturer data.
  static const _serviceUuid = '8f2c9a10-5e3b-4a7d-9c1e-6b4f0a2d7c33';

  final _peripheral = FlutterBlePeripheral();
  final Map<String, MeshPacket> _relayQueue = {};
  final Map<String, DateTime> _relayExpiryAt = {};
  final Map<String, DateTime> _seenAt = {};

  StreamSubscription<List<ScanResult>>? _scanSub;
  Timer? _advertiseTimer;
  Timer? _cleanupTimer;
  int _seq = 0;
  double? _myLat;
  double? _myLon;
  int _rotationIndex = 0;
  bool _canAdvertise = false;

  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  void updateMyLocation(double lat, double lon) {
    _myLat = lat;
    _myLon = lon;
  }

  Future<void> start() async {
    try {
      _canAdvertise = await _peripheral.isSupported;
    } catch (_) {
      _canAdvertise = false;
    }
    _startScanning();
    if (_canAdvertise) {
      _advertiseTimer = Timer.periodic(_advertiseSlot, (_) => _advertiseNext());
    }
    _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) => _cleanup());
  }

  Future<void> stop() async {
    await _scanSub?.cancel();
    await FlutterBluePlus.stopScan();
    _advertiseTimer?.cancel();
    _cleanupTimer?.cancel();
    if (_canAdvertise) {
      try {
        await _peripheral.stop();
      } catch (_) {
        // Nothing to clean up if advertising never actually started.
      }
    }
  }

  void _startScanning() {
    FlutterBluePlus.startScan(
      timeout: const Duration(minutes: 30),
      continuousUpdates: true,
    );
    _scanSub = FlutterBluePlus.scanResults.listen(_onScanResults);
  }

  void _onScanResults(List<ScanResult> results) {
    for (final result in results) {
      final raw = result.advertisementData.manufacturerData[MeshPacket.companyId];
      if (raw == null) continue;
      final packet = MeshPacket.tryParse(Uint8List.fromList(raw));
      if (packet == null || packet.senderId == myShortId) continue;
      _handleIncoming(packet);
    }
  }

  void _handleIncoming(MeshPacket packet) {
    onPacket(packet);

    final key = packet.dedupeKey;
    final now = DateTime.now();
    final alreadyRelayedRecently = _seenAt[key] != null &&
        now.difference(_seenAt[key]!) < _dedupeWindow;
    _seenAt[key] = now;
    if (alreadyRelayedRecently || packet.ttl <= 0 || !_canAdvertise) return;

    _relayQueue[key] = packet.relayed();
    _relayExpiryAt[key] = now.add(_relayExpiry);
  }

  Future<void> _advertiseNext() async {
    final packet = _nextPacketToAdvertise();
    if (packet == null) return;
    try {
      await _peripheral.stop();
      await _peripheral.start(
        advertiseData: AdvertiseData(
          serviceUuid: _serviceUuid,
          manufacturerId: MeshPacket.companyId,
          manufacturerData: packet.toBytes(),
        ),
      );
    } catch (_) {
      // Advertising failed (unsupported chipset/OS build) - stop trying
      // so we don't spam failures every second; scanning/relaying for
      // others keeps working.
      _canAdvertise = false;
      _advertiseTimer?.cancel();
    }
  }

  MeshPacket? _nextPacketToAdvertise() {
    final myPacket = (_myLat != null && _myLon != null)
        ? MeshPacket(
            senderId: myShortId,
            ttl: _maxTtl,
            lat: _myLat!,
            lon: _myLon!,
            seq: _seq,
          )
        : null;

    final candidates = <MeshPacket>[
      if (myPacket != null) myPacket,
      ..._relayQueue.values,
    ];
    if (candidates.isEmpty) return null;

    _rotationIndex = (_rotationIndex + 1) % candidates.length;
    final chosen = candidates[_rotationIndex];
    if (myPacket != null && identical(chosen, myPacket)) {
      _seq = (_seq + 1) & 0xFFFF;
    }
    return chosen;
  }

  void _cleanup() {
    final now = DateTime.now();
    _relayExpiryAt.removeWhere((key, expiry) {
      final expired = now.isAfter(expiry);
      if (expired) _relayQueue.remove(key);
      return expired;
    });
    _seenAt.removeWhere((_, seenAt) => now.difference(seenAt) > _dedupeWindow);
  }
}
