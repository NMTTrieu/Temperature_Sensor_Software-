import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'presentation/screens/splash_screen.dart';

// <-- QUAN TRỌNG: import notifier với alias 'notif'
import 'package:my_app/notifications/notifier.dart' as notif;

// Handler cho FCM khi app ở background/terminated (phải là hàm top-level)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Có thể xử lý thêm nếu cần
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Khởi tạo local notifications + channel (idempotent: gọi nhiều lần cũng OK)
  await notif.Notifier.init();

  // Đăng ký handler background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Quyền thông báo
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  //cho phép hiển thị thông báo khi app đang mở
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Nhận FCM khi app đang foreground -> hiện local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) async {
      final n = msg.notification;
      if (n != null) {
        await notif.localNotif.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          n.title ?? 'Thông báo',
          n.body ?? '',
          NotificationDetails(
            android: AndroidNotificationDetails(
              notif.androidChannel.id,
              notif.androidChannel.name,
              channelDescription: notif.androidChannel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
        );
      }
    });

    // Nhấn vào thông báo mở app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SplashScreen()),
      );
    });

    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
