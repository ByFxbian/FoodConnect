
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
    );

    if(kDebugMode) {
      print("Benachrichtigungsberechtigungen: ${settings.authorizationStatus}");
    }

    if(settings.authorizationStatus == AuthorizationStatus.authorized) {
      _logPermissionStatus("authorized");
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      print("APNS-Token: $apnsToken");
      String? token = await _firebaseMessaging.getToken();
      print("FCM-Token: $token");
      if(token != null) {
        await _saveTokenToFirestore(token);
      }
    } else {
      print("Benachrichtigungen abgelehnt.");
      _logPermissionStatus("denied");
    }

    // ignore: no_leading_underscores_for_local_identifiers
    final _messageStreamController = BehaviorSubject<RemoteMessage>();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Handling a foreground message: ${message.messageId}');
        print('Message data: ${message.data}');
        print('Message notification: ${message.notification?.title}');
        print('Message notification: ${message.notification?.body}');
      }
      //_showNotification(message);
      _messageStreamController.sink.add(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Benutzer hat Benachrichtigung geöffnet");
    });
  }

  static Future<void> _logPermissionStatus(String status) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if(userId.isNotEmpty) {
      await FirebaseFirestore.instance.collection("debug_logs").doc(userId).set({
        'notification_status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  } 

  static Future<void> _saveTokenToFirestore(String token) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
    if(userId.isNotEmpty) {
      await FirebaseFirestore.instance.collection("users").doc(userId).update({
        'notificationToken': token,
      });
    }
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'foodconnect_channel',
        'FoodConnect Benachrichtigungen',
        importance: Importance.max,
        priority: Priority.high,
      );

    const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
    );
  }

  static Future<void> sendNotification({
    required String recipientUserId,
    required String title,
    required String body,
  }) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(recipientUserId).get();
    String? token = userDoc['notificationToken'];
    if(token!=null) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'recipientUserId': recipientUserId,
        'to': token,
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }
}