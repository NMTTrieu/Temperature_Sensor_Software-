import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Plugin thông báo cục bộ (dùng chung toàn app)
final FlutterLocalNotificationsPlugin localNotif =
    FlutterLocalNotificationsPlugin();

/// Channel Android cho cảnh báo
const AndroidNotificationChannel androidChannel = AndroidNotificationChannel(
  'alerts_channel',
  'Alerts',
  description: 'Cảnh báo môi trường',
  importance: Importance.high,
);

/// Khởi tạo plugin + channel
class Notifier {
  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await localNotif.initialize(initSettings);

    await localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }
}
