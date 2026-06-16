import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Thin wrapper around flutter_blue_plus used to discover nearby
/// devices and track the signal strength (RSSI) of a specific
/// paired earbud so the UI can guide the user towards it.
class BluetoothFinderService {
  StreamSubscription<List<ScanResult>>? _scanSub;

  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every(
      (status) => status.isGranted || status.isLimited,
    );
  }

  Future<bool> isBluetoothAvailable() async {
    return await FlutterBluePlus.isSupported;
  }

  Stream<BluetoothAdapterState> get adapterState =>
      FlutterBluePlus.adapterState;

  /// Scans for all nearby BLE devices, used when the user wants to
  /// pick which earbuds to save for later finding.
  Stream<List<ScanResult>> scanForDevices({
    Duration timeout = const Duration(seconds: 8),
  }) {
    FlutterBluePlus.startScan(timeout: timeout);
    return FlutterBluePlus.scanResults;
  }

  Future<void> stopScan() => FlutterBluePlus.stopScan();

  /// Continuously scans and emits the RSSI of the given device id
  /// whenever it is seen in an advertisement, null if not currently
  /// visible. RSSI ranges roughly from -100 (far/weak) to -30 (very
  /// close/strong).
  Stream<int?> trackRssi(String remoteId) {
    final controller = StreamController<int?>.broadcast();
    FlutterBluePlus.startScan(
      timeout: const Duration(minutes: 5),
      continuousUpdates: true,
    );
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      final match = results.where((r) => r.device.remoteId.str == remoteId);
      if (match.isEmpty) {
        controller.add(null);
      } else {
        controller.add(match.first.rssi);
      }
    });
    controller.onCancel = () {
      _scanSub?.cancel();
      FlutterBluePlus.stopScan();
    };
    return controller.stream;
  }

  void dispose() {
    _scanSub?.cancel();
    FlutterBluePlus.stopScan();
  }
}
