import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/screens/home_screen.dart';
import 'package:foodconnect/screens/login_screen.dart';
import 'package:foodconnect/screens/main_screen.dart';
import 'package:foodconnect/screens/signup_screen.dart';
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
  runApp(MyApp(isDarkMode: isDarkMode));
}

Future<bool> _loadThemePreference() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool("isDarkMode") ?? true;
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
          return MainScreen(onThemeChanged: onThemeChanged);
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
