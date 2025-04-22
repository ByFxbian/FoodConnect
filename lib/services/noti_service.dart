import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotiService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /*Future<void> initNotification() async {
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
    _isInitialized = true;
  }*/
  
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
    _isInitialized = true;
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

  /*Future<void> showNotification({int id = 0, String? title, String? body, String? recipientUserId}) async {
    if(!_isInitialized) await initNotification();

    if(recipientUserId == null || recipientUserId.isEmpty) {
      if(kDebugMode) {
        print("NotiService: Keine recipientUserId angegeben, Aktion abgebrochen.");
      }
      return;
    }

    bool recipientEnabled = true;

    try {
      DocumentSnapshot userDoc = await _db.collection("users").doc(recipientUserId).get();
      if (userDoc.exists && userDoc.data() != null) {
         var data = userDoc.data() as Map<String, dynamic>;
         recipientEnabled = data['userNotificationsEnabled'] ?? true;
      }

      if (kDebugMode) {
         print("NotiService: Empfänger $recipientUserId - Benachrichtigungen aktiviert: $recipientEnabled");
       }
    } catch (e) {
       if (kDebugMode) {
         print("NotiService: Fehler beim Lesen der Einstellung für $recipientUserId: $e");
       }
       recipientEnabled = true;
    }

    if (!recipientEnabled) {
       if (kDebugMode) {
         print("NotiService: Benachrichtigung für $recipientUserId blockiert (deaktiviert).");
       }
      return;
    }

    try {
      await _db.collection('notifications').add({
        'recipientUserId': recipientUserId,
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails(),
      );

      if (kDebugMode) {
        print("NotiService: Lokale Benachrichtigung angezeigt und in Firestore gespeichert für $recipientUserId.");
      }
    } catch (e) {
       if (kDebugMode) {
         print("NotiService: Fehler beim Anzeigen/Speichern der Benachrichtigung: $e");
       }
    }
  }*/

  Future<void> logNotificationInDatabase({
    String? title,
    String? body,
    required String? recipientUserId
  }) async {
    if (recipientUserId == null || recipientUserId.isEmpty) {
      if (kDebugMode) {
        print("NotiService (log): Keine recipientUserId angegeben, Aktion abgebrochen.");
      }
      return;
    } 

    try {
      await _db.collection('notifications').add({
        'recipientUserId': recipientUserId,
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      if (kDebugMode) {
        print("NotiService (log): Benachrichtigung in Firestore geloggt für $recipientUserId.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("NotiService (log): Fehler beim Speichern der Benachrichtigung in Firestore: $e");
      }
    }
  }
}