import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onUsernameChanged;
  final ValueChanged<bool> onThemeChanged;

  SettingsScreen({required this.onUsernameChanged, required this.onThemeChanged});  

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = true;
  final TextEditingController _userNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if(mounted) {
        isDarkMode = prefs.getBool("isDarkMode") ?? true;
      }
    });
  }

  Future<void> _toggleTheme(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isDarkMode", value);
    if (mounted) {
      setState(() {
        isDarkMode = value;
      });
    }
    widget.onThemeChanged(value);
  }

  void _updateUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if(user != null && _userNameController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
        "name": _userNameController.text.trim(),
      });
      widget.onUsernameChanged();
      _showConfirmationPopup("Benutzername aktualisiert");
    }
  }

  void _showConfirmationPopup(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 40),
              SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text("OK"),
              )
            ],
          ),
        );
      },
    );
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed("/login");
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Konto löschen"),
        content: Text("Bist du sicher, dass du dein Konto dauerhaft löschen möchtest?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Abbrechen"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAccount();
            },
            child: Text("Löschen", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() async {
    try {
      await FirebaseAuth.instance.currentUser?.delete();
      Navigator.of(context).pushReplacementNamed("/login");
    } catch (e) {
      print("Fehler beim Löschen des Accounts: $e");
    }
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
        title: Text("Einstellungen", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text("Dark Mode", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              value: isDarkMode,
              onChanged: _toggleTheme,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            ListTile(
              title: Text("Benutzernamen ändern", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              trailing: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurface),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Neuen Benutzernamen eingeben", style: TextStyle(color: Theme.of(context).colorScheme.onSurface),),
                    content: TextField(
                      controller: _userNameController,
                      decoration: InputDecoration(hintText: "Neuer Benutzername"),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text("Abbrechen", style: TextStyle(color: Theme.of(context).colorScheme.onSurface),),
                      ),
                      TextButton(
                        onPressed: () {
                          _updateUsername();
                          Navigator.of(context).pop();
                        },
                        child: Text("Speichern", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              title: Text("Abmelden", style: TextStyle(color: Colors.redAccent)),
              onTap: _signOut,
            ),
            ListTile(
              title: Text("Konto löschen", style: TextStyle(color: Colors.redAccent)),
              onTap: _confirmDeleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}