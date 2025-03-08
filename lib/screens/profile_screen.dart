import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/screens/settings_screen.dart';
import 'package:foodconnect/services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {

  ProfileScreen();

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  int followerCount = 0;
  int followingCount = 0;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFollowCounts();
  }

  Future<void> _loadFollowCounts() async {
    int followers = await _firestoreService.getFollowerCount(user!.uid);
    int following = await _firestoreService.getFollowingCount(user!.uid);
    setState(() {
      followerCount = followers;
      followingCount = following;
    });
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
        title: Text(
          "Profil",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(Platform.isIOS ? CupertinoIcons.settings : Icons.settings,
                  color: Theme.of(context).colorScheme.onSurface, size: 26),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<bool>(
                    builder: (context) => SettingsScreen(
                      onUsernameChanged: _loadUserData,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator.adaptive(),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: userData?['photoUrl'] != null &&
                                  userData?['photoUrl'] != ""
                              ? NetworkImage(userData?['photoUrl'])
                              : AssetImage("assets/icons/default_avatar.png")
                                  as ImageProvider,
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
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                Text(
                                  followerCount.toString(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  "Follower",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 20),
                            Column(
                              children: [
                                Text(
                                  followingCount.toString(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  "Folgt",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 30),
                        _buildTasteProfileSection(userData?['tasteProfile']),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTasteProfileSection(Map<String, dynamic>? tasteProfile) {
    bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    if(tasteProfile == null || tasteProfile.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🍽️ Geschmacksprofil",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary),
          ),
          Divider(color: Theme.of(context).colorScheme.primary),
          Text(
            "Keine Informationen vorhanden.",
            style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "🍽️ Geschmacksprofil",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary),
        ),
        isIOS ? Divider() : Divider(color: Theme.of(context).colorScheme.primary),
        ...tasteProfile.entries.map((entry) {
          return _buildTasteProfileRow(_mapKeyToLabel(entry.key), entry.value);
        // ignore: unnecessary_to_list_in_spreads
        }).toList(),
      ],
    );
  }

  Widget _buildTasteProfileRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? "Nicht angegeben",
              style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  String _mapKeyToLabel(String key) {
    switch (key) {
      case "favoriteCuisine":
        return "🌎 Lieblingsküche:";
      case "dietType":
        return "🥗 Ernährung:";
      case "spiceLevel":
        return "🌶️ Schärfe-Level:";
      case "allergies":
        return "🚫 Allergien:";
      case "favoriteTaste":
        return "😋 Lieblingsgeschmack:";
      case "dislikedFoods":
        return "🚫 Mag nicht:";
      default:
        return key;
    }
  }
}