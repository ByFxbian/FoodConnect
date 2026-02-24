import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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

  static Future<void> init() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      provisional: true,
      sound: true,
    );

    if (kDebugMode) {
      print("FCM Berechtigungsstatus: ${settings.authorizationStatus}");
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _getTokenAndSaveConditionally();

      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        if (kDebugMode) {
          print("FCM Token erneuert: $newToken");
        }
        await _saveTokenConditionally(newToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Vordergrund-Nachricht empfangen: ${message.messageId}');
          print(
              'Notification: ${message.notification?.title} / ${message.notification?.body}');
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print(
              'Benachrichtigung geöffnet (App im Hintergrund/geschlossen): ${message.messageId}');
        }

        _handleMessageNavigation(message.data);
      });

      FirebaseMessaging.instance
          .getInitialMessage()
          .then((RemoteMessage? message) {
        if (message != null) {
          if (kDebugMode) {
            print(
                'App durch Klick auf Benachrichtigung gestartet: ${message.messageId}');
          }

          _handleMessageNavigation(message.data);
        }
      });
    } else {
      if (kDebugMode) {
        print("FCM Berechtigung nicht erteilt.");
      }
      await deleteTokenFromFirestore();
    }
  }

  static Future<void> _getTokenAndSaveConditionally() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          print("FCM Token erhalten: $token");
        }
        await _saveTokenConditionally(token);
      } else {
        if (kDebugMode) {
          print("FCM Token konnte nicht geholt werden (null).");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Fehler beim Holen/Speichern des FCM Tokens: $e");
      }
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
        if (kDebugMode) {
          print("FCM Token in Firestore gespeichert für User ${user.uid}.");
        }
      } else {
        if (kDebugMode) {
          print(
              "FCM Token NICHT gespeichert, da userNotificationsEnabled=false für User ${user.uid}.");
        }
        await deleteTokenFromFirestore();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Fehler beim bedingten Speichern des Tokens: $e");
      }
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
      if (kDebugMode) {
        print("FCM Token aus Firestore gelöscht für User ${user.uid}.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Fehler beim Löschen des Tokens aus Firestore: $e");
      }
    }
  }

  static Future<void> _handleMessageNavigation(
      Map<String, dynamic> data) async {
    if (kDebugMode) {
      print("Handling Navigation für Daten: $data");
    }

    final String? type = data['type'];
    final String? screen = data['screen'];

    await Future.delayed(Duration(milliseconds: 300));

    if (navigatorKey.currentState == null) {
      print("Navigator nicht bereit für Benachrichtigungs-Navigation.");
      return;
    }

    try {
      if (type == 'review' &&
          screen == 'homeScreen' &&
          data['restaurantId'] != null) {
        String restaurantId = data['restaurantId'];
        print("Navigiere zur Karte für Restaurant: $restaurantId");

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
          print(
              "Restaurant-Daten für Navigation nicht gefunden (ID: $restaurantId). Navigiere zur Startseite.");

          if (navigatorKey.currentContext != null) {
            navigatorKey.currentContext!.go('/explore');
          }
        }
      } else if (type == 'follow' && screen == 'notificationsScreen') {
        print("Navigiere zur Benachrichtigungsseite.");

        navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (context) => NotificationsScreen()));
      } else {
        print(
            "Unbekannter Benachrichtigungstyp oder fehlende Daten für Navigation.");
      }
    } catch (e) {
      print("🔥 Fehler bei der Benachrichtigungs-Navigation: $e");
    }
  }
}
