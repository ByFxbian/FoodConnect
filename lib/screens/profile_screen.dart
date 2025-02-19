import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/screens/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  ProfileScreen({required this.onThemeChanged});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if(user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

      if(userDoc.exists) {
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          userData = {};
          isLoading = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Profil", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurface, size: 26),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => SettingsScreen(onUsernameChanged: _loadUserData, onThemeChanged: (isDarkMode) {
                    widget.onThemeChanged;
                  })),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: userData?['photoUrl'] != null && userData?['photoUrl'] != ""
                            ? NetworkImage(userData?['photoUrl'])
                            : AssetImage("assets/icons/default_avatar.png") as ImageProvider,
                      ),
                      SizedBox(height: 20),
                      Text(
                        userData?['name'] ?? "Unbekannter Nutzer",
                        key: ValueKey(userData?["name"]),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        userData?['email'] ?? "Keine E-Mail vorhanden",
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}