import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foodconnect/main.dart';
import 'package:foodconnect/screens/username_selection_screen.dart';
import 'package:foodconnect/widgets/primary_button.dart';
import 'package:foodconnect/widgets/social_button.dart';
import 'package:go_router/go_router.dart';
import 'package:foodconnect/widgets/login_field.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      );
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Kein Account mit dieser E-Mail gefunden.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Falsches Passwort. Bitte versuche es erneut.';
      case 'invalid-email':
        return 'Ungültige E-Mail-Adresse.';
      case 'user-disabled':
        return 'Dieses Konto wurde deaktiviert.';
      case 'too-many-requests':
        return 'Zu viele Versuche. Bitte warte einen Moment.';
      case 'network-request-failed':
        return 'Verbindungsfehler. Prüfe deine Internetverbindung.';
      default:
        return 'Anmeldung fehlgeschlagen. Bitte versuche es erneut.';
    }
  }

  Future<void> loginWithEmailAndPassword() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Bitte fülle alle Felder aus.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user?.uid)
          .get();

      if (userDoc.exists) {
        if (mounted) {
          setState(() => isLoading = false);
          await initializeAppData();
          if (mounted) context.go('/explore');
        }
      } else {
        setState(() => isLoading = false);
        _showError('Nutzerprofil nicht gefunden.');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);
      _showError(_mapFirebaseError(e.code));
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Ein unerwarteter Fehler ist aufgetreten.');
    }
  }

  Future<void> loginWithApple() async {
    try {
      final appleProvider = AppleAuthProvider();
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithProvider(appleProvider);
      final User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (!mounted) return;

        if (!userDoc.exists) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UsernameSelectionScreen(user: user),
            ),
          );
        } else {
          await initializeAppData();
          if (mounted) context.go('/explore');
        }
      }
    } catch (e) {
      _showError('Apple-Anmeldung fehlgeschlagen.');
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (!mounted) return;

        if (!userDoc.exists) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UsernameSelectionScreen(user: user),
            ),
          );
        } else {
          await initializeAppData();
          if (mounted) context.go('/explore');
        }
      }
    } catch (e) {
      _showError('Google-Anmeldung fehlgeschlagen.');
    }
  }

  void _showPasswordResetDialog() {
    TextEditingController resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog.adaptive(
          title: const Text("Passwort zurücksetzen"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  "Gib deine E-Mail-Adresse ein, um dein Passwort zurückzusetzen."),
              const SizedBox(height: 12),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  hintText: "E-Mail-Adresse",
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Abbrechen"),
            ),
            FilledButton(
              onPressed: () async {
                final email = resetEmailController.text.trim();
                if (email.isEmpty) return;
                try {
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: email);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _showSuccess("Passwort-Reset E-Mail gesendet!");
                } catch (e) {
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _showError("Fehler: Überprüfe die E-Mail-Adresse.");
                }
              },
              child: const Text("E-Mail senden"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),

                  // ─── Logo / Title ───
                  Icon(
                    Icons.restaurant_rounded,
                    size: 56,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'FoodConnect',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Willkommen zurück',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 40),

                  // ─── Social Login ───
                  SocialButton(
                    iconPath: 'assets/svgs/g_logo.svg',
                    label: 'Weiter mit Google',
                    onTap: loginWithGoogle,
                  ),
                  if (Platform.isIOS) ...[
                    const SizedBox(height: 12),
                    SocialButton(
                      iconPath: 'assets/svgs/a_logo.svg',
                      label: 'Weiter mit Apple',
                      onTap: loginWithApple,
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ─── Divider ───
                  Row(
                    children: [
                      Expanded(
                          child: Divider(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.3))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('oder',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.outline)),
                      ),
                      Expanded(
                          child: Divider(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.3))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ─── Email / Password fields ───
                  LoginField(
                    hintText: 'E-Mail',
                    controller: emailController,
                  ),
                  const SizedBox(height: 12),
                  LoginField(
                    hintText: 'Passwort',
                    controller: passwordController,
                  ),

                  // ─── Forgot password ───
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showPasswordResetDialog,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                      ),
                      child: Text(
                        "Passwort vergessen?",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ─── Login button ───
                  PrimaryButton(
                    pressAction: loginWithEmailAndPassword,
                    buttonLabel: "Anmelden",
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 28),

                  // ─── Register link ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Noch kein Konto? ',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/signup'),
                        child: Text(
                          'Jetzt registrieren',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
