import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/screens/login_screen.dart';
import 'package:foodconnect/screens/taste_profile_screen.dart';
import 'package:foodconnect/widgets/gradient_button.dart';
import 'package:foodconnect/widgets/login_field.dart';

class SignUpScreen extends StatefulWidget {
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
  final usernameController = TextEditingController();
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  Future<void> createUserWithEmailAndPassword() async {
    try {
      if(usernameController.text.trim().isEmpty) {
        setState(() {
          errorMessage = "Bitte gib einen Nutzernamen ein.";
        });
        return;
      }

      bool userNameExists = await checkIfUsernameExists(usernameController.text.trim());
      if(userNameExists) {
        setState(() {
          errorMessage = "Dieser Nutzername ist bereits vergeben.";
        });
        return;
      }

      final userCredential = 
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        await userCredential.user?.sendEmailVerification();

        await FirebaseFirestore.instance.collection("users").doc(userCredential.user?.uid).set({
          "id": userCredential.user?.uid,
          "name": usernameController.text.trim(),
          "email": emailController.text.trim(),
          "photoUrl": "",
          "emailVerified": false,
        });

        print("Nutzer erfolgreich erstellt & in Firestore gespeichert");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TasteProfileScreen(userId: userCredential.user!.uid)),
        );
    } on FirebaseException catch (e) {
      print(e.message);
      setState(() {
        errorMessage = e.message;
      });
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
              const SizedBox(height: 30),
              LoginField(hintText: 'Nutzername', controller: usernameController),
              const SizedBox(height: 15),
              LoginField(hintText: 'Email', controller: emailController),
              const SizedBox(height: 15),
              LoginField(hintText: 'Passwort', controller: passwordController),
              const SizedBox(height: 15),
              if(errorMessage != null) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
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
                  Navigator.pushReplacement(context, LoginScreen.route());
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