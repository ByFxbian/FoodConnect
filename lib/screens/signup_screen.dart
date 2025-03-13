import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
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
  bool isPasswordVisible = false;
  bool isPasswordValid = false;
  bool isLoading = false;

  final RegExp passwordRegex = RegExp(
    r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*()])[A-Za-z\d!@#$%^&*()]{8,}$');

  Map<String, bool> passwordCriteria = {
    "Mindestens 8 Zeichen": false,
    "Mindestens 1 Großbuchstabe": false,
    "Mindestens 1 Zahl": false,
    "Mindestens 1 Sonderzeichen": false,
  };

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  void validatePassword(String password) {
    setState(() {
      passwordCriteria["Mindestens 8 Zeichen"] = password.length >= 8;
      passwordCriteria["Mindestens 1 Großbuchstabe"] =
          password.contains(RegExp(r'[A-Z]'));
      passwordCriteria["Mindestens 1 Zahl"] = password.contains(RegExp(r'\d'));
      passwordCriteria["Mindestens 1 Sonderzeichen"] =
          password.contains(RegExp(r'[!@#$%^&*()]'));

      isPasswordValid = passwordRegex.hasMatch(password);
    });
  }

  Future<void> emptyFunction() async {
    return;
  }

  Future<void> createUserWithEmailAndPassword() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      isLoading = true;
    });
    try {
      
      if(usernameController.text.trim().isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = "Bitte gib einen Nutzernamen ein.";
        });
        return;
      }

      bool userNameExists = await checkIfUsernameExists(usernameController.text.trim());
      if(userNameExists) {
        setState(() {
          isLoading = false;
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
          "lowercaseName": usernameController.text.trim().toLowerCase(),
          "email": emailController.text.trim(),
          "photoUrl": "",
          "emailVerified": false,
        });

        print("Nutzer erfolgreich erstellt & in Firestore gespeichert");
        setState(() {
          isLoading = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TasteProfileScreen(userId: userCredential.user!.uid)),
        );
    } on FirebaseException catch (e) {
      print(e.message);
      setState(() {
        isLoading = false;
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
              //LoginField(hintText: 'Passwort', controller: passwordController),
              _buildPasswordField(),
              _buildPasswordCriteria(),
              const SizedBox(height: 15),
              if(errorMessage != null) 
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              isLoading ? GradientButton(pressAction: emptyFunction, buttonLabel: "Registrieren")
              : GradientButton(pressAction: createUserWithEmailAndPassword, buttonLabel: "Registrieren"),
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

  Widget _buildPasswordField() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 400,
      ),
      child: TextFormField(
        style: TextStyle(color: Colors.white),
        cursorColor: Colors.deepPurple,
        controller: passwordController,
        obscureText: !isPasswordVisible,
        onChanged: validatePassword,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(27),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: isPasswordValid ? Colors.green : Colors.red),
            borderRadius: BorderRadius.circular(10),
          ),
          hintText: "Passwort",
          border: OutlineInputBorder(
            borderSide: BorderSide(color: isPasswordValid ? Colors.green : Colors.red),
            borderRadius: BorderRadius.circular(10),
          ),
          suffixIcon: IconButton(
            icon: Icon(Platform.isIOS ? (isPasswordVisible ? CupertinoIcons.eye : CupertinoIcons.eye_slash) :
              (isPasswordVisible ? Icons.visibility : Icons.visibility_off)
            ),
            onPressed: () {
              setState(() {
                isPasswordVisible = !isPasswordVisible;
              });
            },
          )
        ),
      ),
    );
  }

  Widget _buildPasswordCriteria() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: passwordCriteria.entries.map((entry) {
          return Row(
            children: [
              Padding(
                padding: EdgeInsets.all(3),
              ),
              Icon(
                Platform.isIOS ? (entry.value ? CupertinoIcons.check_mark_circled : CupertinoIcons.xmark_circle) : (entry.value ? Icons.check_circle : Icons.cancel),
                color: entry.value ? Colors.green : Colors.red,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                entry.key,
                style: TextStyle(
                  color: entry.value ? Colors.green : Colors.red,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}