import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:foodconnect/screens/home_screen.dart';
import 'package:foodconnect/screens/login_screen.dart';
import 'package:foodconnect/screens/main_screen.dart';
import 'package:foodconnect/screens/signup_screen.dart';
import 'package:foodconnect/screens/taste_profile_screen.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:foodconnect/utils/Palette.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isDarkMode = prefs.getBool("isDarkMode") ?? true;

  FirestoreService firestoreService = FirestoreService();
  await firestoreService.fetchAndStoreRestaurants();

  runApp(MyApp(isDarkMode: isDarkMode));
}


class MyApp extends StatefulWidget {
  final bool isDarkMode;

  const MyApp({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();

}

class _MyAppState extends State<MyApp> {
  late bool isDarkMode;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
  }

  void _toggleTheme(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isDarkMode", value);
    setState(() {
      isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Connect',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      home: AuthWrapper(onThemeChanged: _toggleTheme),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final ValueChanged<bool> onThemeChanged;

  AuthWrapper({required this.onThemeChanged});

  Future<bool> _hasCompletedTasteProfile(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(userId).get();
    Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;

    return data?["tasteProfile"] != null && data!["tasteProfile"].isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if(snapshot.data != null) {
          String userId = snapshot.data!.uid;

          return FutureBuilder<bool>(
            future: _hasCompletedTasteProfile(userId),
            builder: (context, tasteProfileSnapshot) {
              if(!tasteProfileSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              if(tasteProfileSnapshot.data == false) {
                return TasteProfileScreen(userId: userId);
              }

              return MainScreen(onThemeChanged: onThemeChanged);
            },
          );
        }
        return const SignUpScreen();
      },
    );
  }
}

ThemeData _darkTheme() {
  return ThemeData(
    scaffoldBackgroundColor: Palette.darkBackground,
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      surface: Palette.darkBackground,
      onSurface: Palette.darkTextColor,
      primary: Palette.gradient1,
      secondary: Palette.gradient2,
      onPrimary: Palette.darkTextColor
    ),
  );
}

ThemeData _lightTheme() {
  return ThemeData(
    scaffoldBackgroundColor: Palette.lightBackground,
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      surface: Palette.lightBackground,
      onSurface: Palette.lightTextColor,
      primary: Palette.gradient1,
      secondary: Palette.gradient2,
      onPrimary: Palette.darkTextColor
    )
  );
}
