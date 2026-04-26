import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart'; // 🔥 Fix: Für saubere Premium-Transitions
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodconnect/router/auth_listenable.dart';
import 'package:foodconnect/screens/home_screen.dart';
import 'package:foodconnect/screens/lists_screen.dart';
import 'package:foodconnect/screens/list_detail_screen.dart';
import 'package:foodconnect/screens/profile_screen.dart';
import 'package:foodconnect/screens/login_screen.dart';
import 'package:foodconnect/screens/signup_screen.dart';
import 'package:foodconnect/screens/legal_screens.dart'; // 🔥 Fix: Added legal screens
import 'package:foodconnect/screens/premium_screen.dart';
import 'package:foodconnect/screens/main_screen.dart';
import 'package:foodconnect/screens/onboarding_screen.dart';
import 'package:foodconnect/main.dart'; // To access prefs

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorExploreKey =
    GlobalKey<NavigatorState>(debugLabel: 'explore');
final GlobalKey<NavigatorState> _shellNavigatorListsKey =
    GlobalKey<NavigatorState>(debugLabel: 'lists');
final GlobalKey<NavigatorState> _shellNavigatorProfileKey =
    GlobalKey<NavigatorState>(debugLabel: 'profile');

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/explore',
    refreshListenable: AuthNotifier(),
    redirect: (context, state) {
      final bool loggedIn = FirebaseAuth.instance.currentUser != null;
      final bool isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' || 
          state.matchedLocation == '/legal'; // 🔥 Let people view legal docs before auth
      final bool isOnboarding = state.matchedLocation == '/onboarding';

      if (!loggedIn) {
        return (isAuthRoute || isOnboarding) ? null : '/login';
      }

      // If logged in
      final bool hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

      // Force onboarding if they haven't seen it and they are not already there
      if (!hasSeenOnboarding && !isOnboarding) {
        return '/onboarding';
      }

      // If they HAVE seen onboarding and they are on an auth route or onboarding route, go to explore
      if (hasSeenOnboarding && (isAuthRoute || isOnboarding)) {
        return '/explore';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => SignUpScreen(),
      ),
      GoRoute(
        path: '/legal',
        builder: (context, state) => const LegalScreen(title: "Datenschutz & AGB", content: "$datenschutzText\n\n$agbText"),
      ),
      GoRoute(
        path: '/premium',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const PremiumScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SharedAxisTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                transitionType: SharedAxisTransitionType.scaled,
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorExploreKey,
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorListsKey,
            routes: [
              GoRoute(
                path: '/lists',
                builder: (context, state) => const ListsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (context, state) {
                      final listData = state.extra as Map<String, dynamic>?;
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: ListDetailScreen(
                          listId: state.pathParameters['id']!,
                          listData: listData,
                        ),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return SharedAxisTransition(
                            animation: animation,
                            secondaryAnimation: secondaryAnimation,
                            transitionType: SharedAxisTransitionType.scaled,
                            child: child,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => ProfileScreen(),
              ),
            ],
          ),
        ],
      )
    ],
  );
}
