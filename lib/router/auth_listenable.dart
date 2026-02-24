import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Wraps [FirebaseAuth.authStateChanges] as a [ChangeNotifier] so
/// GoRouter can re-evaluate its redirect guard on sign-in/sign-out.
class AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<User?> _subscription;

  AuthNotifier() {
    _subscription = FirebaseAuth.instance
        .authStateChanges()
        .listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
