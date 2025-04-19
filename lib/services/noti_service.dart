import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotiService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initNotification() async {
    if(_isInitialized) return;

    const initSettingsAndroid = AndroidInitializationSettings('@mipmap/app_icon');

    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    await notificationsPlugin.initialize(initSettings);
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'food_connect_channel_id',
        'Food Connect',
        channelDescription: "Food Connect Notifications",
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> showNotification({int id = 0, String? title, String? body, String? recipientUserId}) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'recipientUserId': recipientUserId,
      'title': title,
      'body': body,
      'timestamp': FieldValue.serverTimestamp(),
    });
    return notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails(),
    );
  }
}