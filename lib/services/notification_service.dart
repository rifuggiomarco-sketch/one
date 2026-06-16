import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Wraps flutter_local_notifications to show the "earbud out of range"
/// alert. The persistent foreground-service notification is managed
/// separately by flutter_background_service itself.
class NotificationService {
  static const _channelId = 'earbud_out_of_range';
  static const _channelName = 'Auricolare fuori portata';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Avviso quando un auricolare esce dal raggio Bluetooth',
      importance: Importance.max,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showOutOfRangeAlert(String deviceName) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription:
          'Avviso quando un auricolare esce dal raggio Bluetooth',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: false,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentSound: true, presentAlert: true),
    );
    await _plugin.show(
      id: deviceName.hashCode,
      title: 'Auricolare fuori portata',
      body: '$deviceName si è allontanato troppo dal telefono.',
      notificationDetails: details,
    );
  }
}
