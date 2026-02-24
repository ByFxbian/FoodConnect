import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/main.dart';
import 'package:foodconnect/widgets/primary_button.dart';
import 'package:go_router/go_router.dart';
import 'package:foodconnect/widgets/login_field.dart';

class UsernameSelectionScreen extends StatefulWidget {
  final User user;

  const UsernameSelectionScreen({super.key, required this.user});

  @override
  State<UsernameSelectionScreen> createState() =>
      _UsernameSelectionScreenState();
}

class _UsernameSelectionScreenState extends State<UsernameSelectionScreen> {
  final TextEditingController usernameController = TextEditingController();
  String? errorMessage;

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  Future<void> _setUsername() async {
    String username = usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        errorMessage = "Bitte gib einen Nutzernamen ein.";
      });
      return;
    }

    bool exists = await _checkIfUsernameExists(username);
    if (exists) {
      setState(() {
        errorMessage = "Dieser Nutzername ist bereits vergeben.";
      });
      return;
    }

    await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.user.uid)
        .set({
      "id": widget.user.uid,
      "name": username,
      "email": widget.user.email,
      "photoUrl": widget.user.photoURL ?? "",
      "emailVerified": true,
    });

    print("✅ Nutzer erfolgreich erstellt: $username");

    if (mounted) {
      await initializeAppData();
      if (mounted) context.go('/explore');
    }
  }

  Future<bool> _checkIfUsernameExists(String username) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection("users")
        .where("name", isEqualTo: username)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Wähle deinen Nutzernamen",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(
              height: 20,
            ),
            LoginField(hintText: 'Nutzername', controller: usernameController),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            const SizedBox(
              height: 20,
            ),
            PrimaryButton(pressAction: _setUsername, buttonLabel: "Weiter"),
          ],
        ),
      ),
    ));
  }
}
