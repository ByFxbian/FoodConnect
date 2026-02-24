import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:foodconnect/services/app_logger.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:foodconnect/main.dart';
import 'package:foodconnect/screens/profile_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:foodconnect/services/database_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final _log = AppLogger();

  static Future<void> init() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      provisional: true,
      sound: true,
    );

    _log.info('FCM', 'Berechtigungsstatus: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _getTokenAndSaveConditionally();

      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        _log.info('FCM', 'Token erneuert');
        await _saveTokenConditionally(newToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _log.info(
            'FCM', 'Vordergrund-Nachricht empfangen: ${message.messageId}');
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _log.info('FCM', 'Benachrichtigung geöffnet: ${message.messageId}');

        _handleMessageNavigation(message.data);
      });

      FirebaseMessaging.instance
          .getInitialMessage()
          .then((RemoteMessage? message) {
        if (message != null) {
          _log.info('FCM',
              'App durch Benachrichtigung gestartet: ${message.messageId}');

          _handleMessageNavigation(message.data);
        }
      });
    } else {
      _log.warn('FCM', 'Berechtigung nicht erteilt.');
      await deleteTokenFromFirestore();
    }
  }

  static Future<void> _getTokenAndSaveConditionally() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        _log.info('FCM', 'Token erhalten');
        await _saveTokenConditionally(token);
      } else {
        _log.warn('FCM', 'Token konnte nicht geholt werden (null).');
      }
    } catch (e) {
      _log.error('FCM', 'Fehler beim Holen/Speichern des Tokens', error: e);
    }
  }

  static Future<void> _saveTokenConditionally(String token) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc =
          await _db.collection("users").doc(user.uid).get();
      bool userEnabled = true;

      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        userEnabled = data['userNotificationsEnabled'] ?? true;
      }

      if (userEnabled) {
        await _db
            .collection("users")
            .doc(user.uid)
            .set({'notificationToken': token}, SetOptions(merge: true));
        _log.info(
            'FCM', 'Token in Firestore gespeichert für User ${user.uid}.');
      } else {
        _log.info('FCM',
            'Token nicht gespeichert (deaktiviert für User ${user.uid}).');
        await deleteTokenFromFirestore();
      }
    } catch (e) {
      _log.error('FCM', 'Fehler beim bedingten Speichern des Tokens', error: e);
    }
  }

  static Future<void> saveTokenToFirestore() async {
    await _getTokenAndSaveConditionally();
  }

  static Future<void> deleteTokenFromFirestore() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db.collection("users").doc(user.uid).set({
        'notificationToken': FieldValue.delete(),
      }, SetOptions(merge: true));
      _log.info('FCM', 'Token aus Firestore gelöscht für User ${user.uid}.');
    } catch (e) {
      _log.error('FCM', 'Fehler beim Löschen des Tokens', error: e);
    }
  }

  static Future<void> _handleMessageNavigation(
      Map<String, dynamic> data) async {
    _log.info('FCM', 'Handling Navigation für Daten: $data');

    final String? type = data['type'];
    final String? screen = data['screen'];

    await Future.delayed(Duration(milliseconds: 300));

    if (navigatorKey.currentState == null) {
      _log.warn(
          'FCM', 'Navigator nicht bereit für Benachrichtigungs-Navigation.');
      return;
    }

    try {
      if (type == 'review' &&
          screen == 'homeScreen' &&
          data['restaurantId'] != null) {
        String restaurantId = data['restaurantId'];
        _log.info('FCM', 'Navigiere zur Karte für Restaurant: $restaurantId');

        DatabaseService dbService = DatabaseService();
        Map<String, dynamic>? restaurantData =
            await dbService.getRestaurantById(restaurantId);

        if (restaurantData != null &&
            restaurantData['latitude'] != null &&
            restaurantData['longitude'] != null) {
          LatLng targetLocation =
              LatLng(restaurantData['latitude'], restaurantData['longitude']);

          if (navigatorKey.currentContext != null) {
            navigatorKey.currentContext!.go('/explore', extra: {
              'targetLocation': targetLocation,
              'selectedRestaurantId': restaurantId,
            });
          }
        } else {
          _log.warn('FCM',
              'Restaurant-Daten nicht gefunden (ID: $restaurantId), navigiere zur Startseite.');

          if (navigatorKey.currentContext != null) {
            navigatorKey.currentContext!.go('/explore');
          }
        }
      } else if (type == 'follow' && screen == 'notificationsScreen') {
        _log.info('FCM', 'Navigiere zur Benachrichtigungsseite.');

        navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (context) => NotificationsScreen()));
      } else {
        _log.warn(
            'FCM', 'Unbekannter Benachrichtigungstyp oder fehlende Daten.');
      }
    } catch (e) {
      _log.error('FCM', 'Fehler bei der Benachrichtigungs-Navigation',
          error: e);
    }
  }
}
