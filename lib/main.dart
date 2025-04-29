import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/screens/loading_screen.dart';
// ignore: unused_import
import 'package:foodconnect/services/noti_service.dart';
// ignore: unused_import
import 'package:foodconnect/services/notification_service.dart';
import 'package:foodconnect/utils/marker_manager.dart';
import 'package:provider/provider.dart';
import 'package:foodconnect/screens/main_screen.dart';
import 'package:foodconnect/screens/signup_screen.dart';
import 'package:foodconnect/screens/taste_profile_screen.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:foodconnect/utils/Palette.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:timeago/timeago.dart' as timeago;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  
    return true;
  };

  //NotiService().initNotification();
  timeago.setLocaleMessages('de', timeago.DeMessages());
  timeago.setLocaleMessages('de_short', timeago.DeShortMessages());

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    )
  );
}


class MyApp extends StatefulWidget {

  const MyApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();

}

class _MyAppState extends State<MyApp> {
  String _lastMessage = "";

  @override
  void initState() {
    super.initState();
    FirestoreService().updateEmailVerificationStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Food Connect',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: AuthWrapper(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class ThemePreferences {
  // ignore: constant_identifier_names
  static const THEME_KEY = "theme_key";

  setTheme(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(THEME_KEY, value);
  }

  getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(THEME_KEY) ?? false;
  }
}

class AuthWrapper extends StatelessWidget {
  AuthWrapper();

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
          return LoadingScreen();
        }
        if(snapshot.data != null) {
          String userId = snapshot.data!.uid;

          return FutureBuilder<bool>(
            future: _hasCompletedTasteProfile(userId),
            builder: (context, tasteProfileSnapshot) {
              if(!tasteProfileSnapshot.hasData) {
                return LoadingScreen();
              }

              if(tasteProfileSnapshot.data == false) {
                return TasteProfileScreen(userId: userId);
              }

              return FutureBuilder(
                future: _initializeAppData(),
                builder: (context, initSnapshot) {
                  if(initSnapshot.connectionState == ConnectionState.waiting) {
                    return LoadingScreen();
                  }
                  if(initSnapshot.hasError) {
                    print("Fehler während der App-Initialisierung: ${initSnapshot.error}");
                  }
                  return MainScreen();
                },
              );
            },
          );
        }
        return const SignUpScreen();
      },
    );
  }
}

Future<void> _initializeAppData() async {
  print("⏳ Initialisiere App-Daten (Restaurants/Marker)...");
  await _initializeData();
  print("✅ App-Daten initialisiert.");

  if (FirebaseAuth.instance.currentUser != null) {
    print("⏳ Initialisiere FCM Notification Service...");
    try {
      await NotificationService.init();
      print("✅ FCM Notification Service initialisiert.");
    } catch (e) {
      print("🔥 Fehler bei der FCM-Initialisierung: $e");
    }
  } else {
    print("⚠️ Nutzer nicht eingeloggt bei FCM-Initialisierung.");
  }
}

Future<void> _initializeData() async {
  print("⚡ Lade Restaurants...");
  FirestoreService firestoreService = FirestoreService();
  await firestoreService.fetchAndStoreRestaurants();
  await MarkerManager().loadMarkers();
  print("✅ Marker geladen!");
}

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Palette.darkBackground,
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    surface: Palette.darkBackground,
    onSurface: Palette.darkTextColor,
    primary: Palette.gradient1,
    secondary: Palette.gradient2,
    onPrimary: Palette.darkTextColor
  ),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  splashFactory: NoSplash.splashFactory
);

final lightTheme = ThemeData(
  scaffoldBackgroundColor: Palette.lightBackground,
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: Palette.lightBackground,
    onSurface: Palette.lightTextColor,
    primary: Palette.gradient1,
    secondary: Palette.gradient2,
    onPrimary: Palette.darkTextColor
  ),
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  splashFactory: NoSplash.splashFactory
);