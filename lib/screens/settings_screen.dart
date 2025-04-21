// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: unused_import
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodconnect/main.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onUsernameChanged;

  SettingsScreen({required this.onUsernameChanged});  

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool isDarkMode;
  final TextEditingController _userNameController = TextEditingController();
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool notificationsEnabled = false;

  bool userNotificationsEnabled = true;
  bool _isLoadingPreferences = true;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    //_loadNotificationPreference();
    _loadUserNotificationPreference();
  }

  Future<void> _loadUserNotificationPreference() async {
    setState(() {
      _isLoadingPreferences = true;
    });
    User? user = FirebaseAuth.instance.currentUser;
    if(user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
        if(userDoc.exists && userDoc.data() != null) {
          var data = userDoc.data() as Map<String, dynamic>;

          setState(() {
            userNotificationsEnabled = data['userNotificationsEnabled'] ?? true;
          });
        } else {
          setState(() {
            userNotificationsEnabled = true;
          });
        }
      } catch (e) {
        print("Fehler beim Laden der Benachrichtigungseinstellung: $e");
         setState(() {
           userNotificationsEnabled = true;
         });
      } finally {
        setState(() {
          _isLoadingPreferences = false;
        });
      }
    } else {
      setState(() {
        userNotificationsEnabled = true;
        _isLoadingPreferences = false;
      });
    }
  }

  Future<void> _loadProfileImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    if(user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      if(userDoc.exists) {
        setState(() {
          _profileImageUrl = userDoc["photoUrl"];
        });
      }
    }
  }

  Future<void> _loadNotificationPreference() async {
    User? user = FirebaseAuth.instance.currentUser;
    if(user!=null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      if(userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;

        setState(() {
          notificationsEnabled = data.containsKey("notificationToken") && data["notificationToken"] != "";
        });
      }
    }
  }

  /*Future<void> _toggleNotifications(bool value) async {
    User? user = FirebaseAuth.instance.currentUser;
    if(user==null) return;

    if(value) {
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
      if(settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await FirebaseMessaging.instance.getToken();
        if(token!=null) {
          await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
            "notificationToken": token,
          });
        } 
      }
    } else {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
        "notificationToken": FieldValue.delete(),
      });
    }

    setState(() {
      notificationsEnabled = value;
    });
  }*/

  Future<void> _toggleNotifications(bool value) async {
    User? user = FirebaseAuth.instance.currentUser;
    if(user==null) return;

    try {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        'userNotificationsEnabled': value,
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          userNotificationsEnabled = value;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Benachrichtigungseinstellung gespeichert."), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      print("Fehler beim Speichern der Benachrichtigungseinstellung: $e");
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("Fehler beim Speichern der Einstellung."), backgroundColor: Colors.red),
       );
       
    }
  }

  Future<bool> checkIfUsernameExists(String username) async {
    final querySnapshot = await FirebaseFirestore.instance
      .collection("users")
      .where("name", isEqualTo: username)
      .get();
    return querySnapshot.docs.isNotEmpty;
  }

  void _updateUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if(user != null && _userNameController.text.isNotEmpty) {
      bool userNameExists = await checkIfUsernameExists(_userNameController.text.trim());
      if (userNameExists) {
        _showConfirmationPopup("Benutzername ist vergeben", false);
        return;
      }
      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
        "name": _userNameController.text.trim(),
        "lowercaseName": _userNameController.text.trim().toLowerCase(),
      });


      await FirestoreService().updateUsernameInReviews(user.uid, _userNameController.text.trim());

      widget.onUsernameChanged();
      _showConfirmationPopup("Benutzername aktualisiert", true);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if(pickedFile == null) return;

    File file = File(pickedFile.path);
    User? user = FirebaseAuth.instance.currentUser;

    if(user!=null) {
      String filePath = "profile_images/${user.uid}.jpg";
      UploadTask uploadTask = FirebaseStorage.instance.ref().child(filePath).putFile(file);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
        "photoUrl": downloadUrl,
      });

      setState(() {
        _profileImageUrl = downloadUrl;
      });

      _showConfirmationPopup("Profilbild aktualisiert", true);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Platform.isIOS ? CupertinoIcons.camera : Icons.camera_alt, color: Theme.of(context).colorScheme.primary),
                title: Text("Kamera verwenden"),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Platform.isIOS ? CupertinoIcons.collections : Icons.photo_library),
                title: Text("Galerie öffnen"),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              )
            ],
          ),
        );
      }
    );
  }
 
  void _showConfirmationPopup(String message, bool passed) {
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
              passed ? Icon(Platform.isIOS ? CupertinoIcons.check_mark_circled : Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 40) :
                Icon(Platform.isIOS ? CupertinoIcons.xmark_circle : Icons.close_outlined, color: Theme.of(context).colorScheme.primary, size: 40),
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
    Navigator.pop(context);
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
       Navigator.of(context).pushNamedAndRemoveUntil(
        '/LoginScreen',
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print("Fehler beim Löschen des Accounts: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Einstellungen", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                        ? ResizeImage(NetworkImage(_profileImageUrl!), height: 420, policy: ResizeImagePolicy.fit)
                        : ResizeImage(AssetImage("assets/icons/default_avatar.png"), height: 420, policy: ResizeImagePolicy.fit) as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        radius: 20,
                        child: Icon(Platform.isIOS ? CupertinoIcons.camera : Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            SwitchListTile.adaptive(
              title: Text("Dark Mode", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (_) {
                themeProvider.toggleTheme();
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            SwitchListTile.adaptive(
              title: Text("Push-Benachrichtigungen", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              value: userNotificationsEnabled,
              onChanged: _toggleNotifications,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            ListTile(
              title: Text("Benutzernamen ändern", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              trailing: Icon(Platform.isIOS ? CupertinoIcons.pencil : Icons.edit, color: Theme.of(context).colorScheme.onSurface),
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