import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foodconnect/screens/home_screen.dart';
import 'package:foodconnect/screens/signup_screen.dart';
import 'package:foodconnect/widgets/gradient_button.dart';
import 'package:foodconnect/widgets/login_field.dart';
import 'package:foodconnect/widgets/social_button.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LoginScreen extends StatefulWidget {
  //const LoginScreen({Key? key}) : super(key: key);
  static route() => MaterialPageRoute(
    builder: (context) => const LoginScreen(),
  );
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginWithEmailAndPassword() async {
    try {
      final userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user?.uid)
          .get();

        if(userDoc.exists) {
          print("Nutzer geladen: ${userDoc["name"]}");
        } else {
          print("Fehler: Nutzer nicht in Firestore gefunden.");
        }

    } on FirebaseException catch(e) {
      print(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Image.asset('assets/images/signin_balls.png'),
              const Text(
                'Food Connect',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 50,
                  color: Colors.white
                ),
              ),
              const SizedBox(height: 50),
              const SocialButton(iconPath: 'assets/svgs/g_logo.svg', label: 'Weiter mit Google'),
              const SizedBox(height: 20),
              const SocialButton(
                iconPath: 'assets/svgs/f_logo.svg',
                label: 'Weiter mit Facebook',
                horizontalPadding: 90,
              ),
              const SizedBox(height: 15),
              const Text(
                'oder',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey
                ),
              ),
              const SizedBox(height: 15),
              LoginField(hintText: 'Email', controller: emailController),
              const SizedBox(height: 15),
              LoginField(hintText: 'Passwort', controller: passwordController),
              const SizedBox(height: 20),
              GradientButton(pressAction: loginWithEmailAndPassword, buttonLabel: "Anmelden"),
              const SizedBox(height: 15),
              const Text(
                'oder',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey
                ),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, SignUpScreen.route());
                },
                child: RichText(
                  text: TextSpan(
                    text: 'Erstelle einen neuen Account',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}