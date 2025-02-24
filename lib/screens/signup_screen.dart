import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/screens/login_screen.dart';
import 'package:foodconnect/screens/taste_profile_screen.dart';
import 'package:foodconnect/widgets/gradient_button.dart';
import 'package:foodconnect/widgets/login_field.dart';

class SignUpScreen extends StatefulWidget {
  //const LoginScreen({Key? key}) : super(key: key);
  static route() => MaterialPageRoute(
    builder: (context) => const SignUpScreen(),
  );
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> createUserWithEmailAndPassword() async {
    try {
      final userCredential = 
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        await FirebaseFirestore.instance.collection("users").doc(userCredential.user?.uid).set({
          "id": userCredential.user?.uid,
          "name": emailController.text.split("@")[0],
          "email": emailController.text.trim(),
          "photoUrl": "",
        });

        print("Nutzer erfolgreich erstellt & in Firestore gespeichert");

        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => TasteProfileScreen(userId: userCredential.user!.uid)),
        );
    } on FirebaseException catch (e) {
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
                'Registrieren',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 50),
              LoginField(hintText: 'Email', controller: emailController),
              const SizedBox(height: 15),
              LoginField(hintText: 'Passwort', controller: passwordController),
              const SizedBox(height: 20),
              GradientButton(pressAction: createUserWithEmailAndPassword, buttonLabel: "Registrieren"),
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
                  Navigator.push(context, LoginScreen.route());
                },
                child: RichText(
                  text: TextSpan(
                    text: 'Melde dich an',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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