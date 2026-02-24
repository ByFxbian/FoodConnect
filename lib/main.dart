import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:foodconnect/services/noti_service.dart';
// ignore: unused_import
import 'package:foodconnect/services/notification_service.dart';
import 'package:foodconnect/utils/app_theme.dart';
import 'package:foodconnect/utils/marker_manager.dart';
import 'package:provider/provider.dart';
import 'package:foodconnect/router/app_router.dart';
import 'package:foodconnect/services/firestore_service.dart';

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

  timeago.setLocaleMessages('de', timeago.DeMessages());
  timeago.setLocaleMessages('de_short', timeago.DeShortMessages());

  await initializeAppData();

  runApp(ChangeNotifierProvider(
    create: (_) => ThemeProvider(),
    child: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    FirestoreService().updateEmailVerificationStatus();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.router,
      title: 'Food Connect',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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

Future<void> initializeAppData() async {
  print("⏳ Initialisiere App-Daten (Restaurants/Marker)...");
  await MarkerManager().loadCustomIcons();
  print("✅ App-Daten initialisiert.");

  if (FirebaseAuth.instance.currentUser != null) {
    print("⏳ Initialisiere FCM Notification Service...");
    try {
      await NotificationService.init();
      print("✅ FCM Notification Service initialisiert.");
    } catch (e) {
      print("🔥 Fehler bei der FCM-Initialisierung: $e");
    }

    FirestoreService firestoreService = FirestoreService();
    await firestoreService.fetchAndStoreRestaurants();
  } else {
    print("⚠️ Nutzer nicht eingeloggt bei FCM-Initialisierung.");
  }
}
