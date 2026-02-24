import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foodconnect/widgets/primary_button.dart';
import 'package:foodconnect/widgets/taste_profile_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:foodconnect/widgets/login_field.dart';

class SignUpScreen extends StatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const SignUpScreen(),
      );
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();
  bool isPasswordVisible = false;
  bool isPasswordValid = false;
  bool isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final RegExp passwordRegex = RegExp(
      r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*()])[A-Za-z\d!@#$%^&*()]{8,}$');

  Map<String, bool> passwordCriteria = {
    "Mind. 8 Zeichen": false,
    "1 Großbuchstabe": false,
    "1 Zahl": false,
    "1 Sonderzeichen": false,
  };

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
    usernameController.dispose();
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

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Diese E-Mail-Adresse wird bereits verwendet.';
      case 'weak-password':
        return 'Das Passwort ist zu schwach.';
      case 'invalid-email':
        return 'Ungültige E-Mail-Adresse.';
      case 'operation-not-allowed':
        return 'Registrierung ist momentan deaktiviert.';
      default:
        return 'Registrierung fehlgeschlagen. Bitte versuche es erneut.';
    }
  }

  void validatePassword(String password) {
    setState(() {
      passwordCriteria["Mind. 8 Zeichen"] = password.length >= 8;
      passwordCriteria["1 Großbuchstabe"] = password.contains(RegExp(r'[A-Z]'));
      passwordCriteria["1 Zahl"] = password.contains(RegExp(r'\d'));
      passwordCriteria["1 Sonderzeichen"] =
          password.contains(RegExp(r'[!@#$%^&*()]'));
      isPasswordValid = passwordRegex.hasMatch(password);
    });
  }

  Future<void> createUserWithEmailAndPassword() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty) {
      _showError("Bitte gib einen Nutzernamen ein.");
      return;
    }
    if (email.isEmpty) {
      _showError("Bitte gib eine E-Mail-Adresse ein.");
      return;
    }
    if (!isPasswordValid) {
      _showError("Das Passwort erfüllt nicht alle Kriterien.");
      return;
    }

    setState(() => isLoading = true);

    try {
      bool userNameExists = await checkIfUsernameExists(username);
      if (userNameExists) {
        setState(() => isLoading = false);
        _showError("Dieser Nutzername ist bereits vergeben.");
        return;
      }

      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.sendEmailVerification();

      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user?.uid)
          .set({
        "id": userCredential.user?.uid,
        "name": username,
        "lowercaseName": username.toLowerCase(),
        "email": email,
        "photoUrl": "",
        "emailVerified": false,
      });

      setState(() => isLoading = false);

      if (!mounted) return;
      context.go('/explore');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          TasteProfileSheet.show(context, dismissible: false);
        }
      });
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);
      _showError(_mapFirebaseError(e.code));
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Ein unerwarteter Fehler ist aufgetreten.');
    }
  }

  Future<bool> checkIfUsernameExists(String username) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection("users")
        .where("name", isEqualTo: username)
        .get();
    return querySnapshot.docs.isNotEmpty;
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

                  // ─── Title ───
                  Icon(
                    Icons.person_add_rounded,
                    size: 56,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Konto erstellen',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Werde Teil von FoodConnect',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ─── Fields ───
                  LoginField(
                    hintText: 'Nutzername',
                    controller: usernameController,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  LoginField(
                    hintText: 'E-Mail',
                    controller: emailController,
                  ),
                  const SizedBox(height: 12),

                  // ─── Password field with toggle ───
                  _buildPasswordField(),
                  const SizedBox(height: 12),

                  // ─── Password criteria ───
                  _buildPasswordCriteria(),
                  const SizedBox(height: 24),

                  // ─── Register button ───
                  PrimaryButton(
                    pressAction: createUserWithEmailAndPassword,
                    buttonLabel: "Registrieren",
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 28),

                  // ─── Login link ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Schon ein Konto? ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Anmelden',
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

  Widget _buildPasswordField() {
    return LoginField(
      hintText: 'Passwort',
      controller: passwordController,
      obscureText: !isPasswordVisible,
      onChanged: validatePassword,
      suffixIcon: IconButton(
        icon: Icon(
          Platform.isIOS
              ? (isPasswordVisible
                  ? CupertinoIcons.eye
                  : CupertinoIcons.eye_slash)
              : (isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          size: 20,
          color: Theme.of(context).colorScheme.outline,
        ),
        onPressed: () {
          setState(() => isPasswordVisible = !isPasswordVisible);
        },
      ),
    );
  }

  Widget _buildPasswordCriteria() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: passwordCriteria.entries.map((entry) {
        final met = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              met
                  ? (Platform.isIOS
                      ? CupertinoIcons.check_mark_circled_solid
                      : Icons.check_circle)
                  : (Platform.isIOS
                      ? CupertinoIcons.circle
                      : Icons.radio_button_unchecked),
              color: met ? Colors.green : Theme.of(context).colorScheme.outline,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              entry.key,
              style: TextStyle(
                fontSize: 12,
                color:
                    met ? Colors.green : Theme.of(context).colorScheme.outline,
                fontWeight: met ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
