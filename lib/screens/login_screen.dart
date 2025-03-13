import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/main.dart';
import 'package:foodconnect/screens/signup_screen.dart';
import 'package:foodconnect/screens/username_selection_screen.dart';
import 'package:foodconnect/widgets/gradient_button.dart';
import 'package:foodconnect/widgets/login_field.dart';
import 'package:foodconnect/widgets/social_button.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
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
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

   Future<void> emptyFunction() async {
    return;
   }

  Future<void> loginWithEmailAndPassword() async {
    setState(() {
      isLoading = true;
    });
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

          if(mounted) {
            setState(() {
              isLoading = false;
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AuthWrapper()),
            );
          }
        } else {
           setState(() {
              isLoading = false;
            });
          print("Fehler: Nutzer nicht in Firestore gefunden.");
        }

    } on FirebaseException catch(e) {
      setState(() {
        isLoading = false;
      });
      print(e.message);
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if(googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if(user!=null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

        if(!userDoc.exists) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UsernameSelectionScreen(user: user),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AuthWrapper()), 
          );
        }
      }
    } catch (e) {
      print("Fehler beim Google-Login: $e");
    }
  }

  void _showPasswordResetDialog() {
    TextEditingController resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog.adaptive(
          title: Text("Passwort zurücksetzen"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Gib deine E-MailAdresse ein, um dein Passwort zurückzusetzen."),
              SizedBox(height: 10),
              TextField(
                controller: resetEmailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "E-Mail Adresse"
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Abbrechen"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: resetEmailController.text.trim(),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Passwort-Reset E-Mail gesendet!"), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Fehler: Überprüfe die E-Mail-Adresse."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text("E-Mail senden"),
            ),
          ],
        );
      },
    );
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
              SocialButton(iconPath: 'assets/svgs/g_logo.svg', label: 'Weiter mit Google', onTap: loginWithGoogle),
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showPasswordResetDialog,
                  child: Text("Passwort vergessen?"),
                ),
              ),
              const SizedBox(height: 20),
              isLoading ? GradientButton(pressAction: emptyFunction, buttonLabel: "Wird angemeldet...")
              : GradientButton(pressAction: loginWithEmailAndPassword, buttonLabel: "Anmelden"),
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
                  Navigator.pushReplacement(context, SignUpScreen.route());
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