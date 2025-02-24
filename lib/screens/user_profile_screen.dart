import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserProfileScreen extends StatefulWidget{
  final String userId;

  UserProfileScreen({ required this.userId});

  @override
  // ignore: library_private_types_in_public_api
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .get();

    if (userDoc.exists) {
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

  String _pixelateEmail(String email) {
    if (!email.contains("@")) return email;
    List<String> parts = email.split("@");
    String domain = parts.last;
    String pixelated = parts.first.length > 3
        ? "${parts.first.substring(0, 3)}***"
        : "***";
    return "$pixelated@$domain";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Profil",
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: userData?['photoUrl'] != null &&
                                  userData?['photoUrl'] != ""
                              ? NetworkImage(userData?['photoUrl'])
                              : AssetImage("assets/icons/default_avatar.png")
                                  as ImageProvider,
                        ),
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: Text(
                          userData?['name'] ?? "Unbekannter Nutzer",
                          key: ValueKey(userData?["name"]),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          userData?['email'] != null
                              ? _pixelateEmail(userData?['email'])
                              : "Keine E-Mail vorhanden",
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      _buildTasteProfileSection(userData?['tasteProfile']),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTasteProfileSection(Map<String, dynamic>? tasteProfile) {
    if (tasteProfile == null || tasteProfile.isEmpty) {
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
        Divider(color: Theme.of(context).colorScheme.primary),
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
        return "⚠️ Allergien:";
      case "favoriteTaste":
        return "😋 Lieblingsgeschmack:";
      case "dislikedFoods":
        return "🚫 Mag nicht:";
      default:
        return key;
    }
  }
}