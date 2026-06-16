import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'bluetooth_finder_service.dart';
import 'notification_service.dart';
import 'ring_service.dart';
import 'storage_service.dart';

/// How long a saved device may go unseen by the BLE scan before it is
/// considered "out of range" and the warning alert fires.
const _outOfRangeTimeout = Duration(seconds: 12);
const _checkInterval = Duration(seconds: 3);

/// How long the loud "ritrovami" tone keeps ringing through the
/// earbud's audio output after it is detected out of range, before it
/// stops automatically (it can also be re-triggered from the app).
const _autoRingDuration = Duration(seconds: 20);

/// Controls the persistent background service that keeps scanning for
/// the user's saved earbuds and warns them as soon as one goes out of
/// Bluetooth range. On Android this keeps running, via a foreground
/// service with a permanent notification, even after the app is closed.
/// On iOS, background BLE scanning is heavily restricted by the system,
/// so monitoring is only reliable while the app is in the foreground.
class ProximityMonitorService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  /// The background service plugin only supports Android and iOS; guard
  /// every call so the app (and its tests) still work on other
  /// platforms, just without the out-of-range monitoring feature.
  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> initialize() async {
    if (!isSupported) return;
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        notificationChannelId: 'earbud_monitoring',
        initialNotificationTitle: 'Trova i tuoi auricolari',
        initialNotificationContent: 'Avvio del monitoraggio...',
        foregroundServiceNotificationId: 4242,
        foregroundServiceTypes: [AndroidForegroundType.connectedDevice],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
      ),
    );
  }

  static Future<void> start() async {
    if (!isSupported) return;
    await _service.startService();
  }

  static Future<bool> isRunning() async {
    if (!isSupported) return false;
    return _service.isRunning();
  }

  static void stop() {
    if (!isSupported) return;
    _service.invoke('stopService');
  }
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final storage = StorageService();
  final bluetooth = BluetoothFinderService();
  final ring = RingService();
  final notifications = NotificationService();
  await notifications.init();
  await bluetooth.requestPermissions();

  final lastSeen = <String, DateTime>{};
  final isOutOfRange = <String, bool>{};
  final autoRingTimers = <String, Timer>{};

  final scanSub = bluetooth.scanResultsStream.listen((results) {
    final now = DateTime.now();
    for (final r in results) {
      lastSeen[r.device.remoteId.str] = now;
    }
  });

  Timer? timer;
  StreamSubscription? stopSub;

  void cleanUpAndStop() {
    timer?.cancel();
    scanSub.cancel();
    for (final t in autoRingTimers.values) {
      t.cancel();
    }
    bluetooth.dispose();
    ring.dispose();
    stopSub?.cancel();
    service.stopSelf();
  }

  stopSub = service.on('stopService').listen((event) => cleanUpAndStop());

  timer = Timer.periodic(_checkInterval, (_) async {
    await bluetooth.ensureScanning();

    final devices = await storage.loadDevices();
    final now = DateTime.now();
    var inRangeCount = 0;

    for (final device in devices) {
      final seen = lastSeen[device.remoteId];
      final inRange =
          seen != null && now.difference(seen) < _outOfRangeTimeout;
      final wasOutOfRange = isOutOfRange[device.remoteId] ?? false;

      if (inRange) {
        inRangeCount++;
        isOutOfRange[device.remoteId] = false;
        if (autoRingTimers.containsKey(device.remoteId)) {
          autoRingTimers.remove(device.remoteId)?.cancel();
          await ring.stopRinging();
        }
      } else if (!wasOutOfRange && seen != null) {
        isOutOfRange[device.remoteId] = true;
        // 1. short warning tone + notification so the user notices
        // immediately that an earbud has disappeared.
        await notifications.showOutOfRangeAlert(device.name);
        await ring.playOutOfRangeWarning();
        // 2. then make the earbud itself ring loudly for a while so
        // it can be located by ear (only audible if it's still
        // connected over the Bluetooth audio profile).
        await Future.delayed(const Duration(milliseconds: 1600));
        await ring.startRinging();
        autoRingTimers[device.remoteId] = Timer(_autoRingDuration, () {
          autoRingTimers.remove(device.remoteId);
          ring.stopRinging();
        });
      }
    }

    if (service is AndroidServiceInstance &&
        await service.isForegroundService()) {
      service.setForegroundNotificationInfo(
        title: 'Trova i tuoi auricolari',
        content: devices.isEmpty
            ? 'Aggiungi un auricolare da monitorare'
            : '$inRangeCount/${devices.length} auricolari nel raggio',
      );
    }
  });
}
