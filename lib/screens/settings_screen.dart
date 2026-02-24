// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: unused_import
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:foodconnect/services/notification_service.dart';
import 'package:foodconnect/utils/snackbar_helper.dart';
import 'package:foodconnect/services/app_logger.dart';
import 'package:foodconnect/widgets/taste_profile_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onUsernameChanged;

  SettingsScreen({required this.onUsernameChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool isDarkMode;
  final TextEditingController _userNameController = TextEditingController();
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool notificationsEnabled = false;

  bool userNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadUserNotificationPreference();
  }

  Future<void> _loadUserNotificationPreference() async {
    if (!mounted) return;
    if (!mounted) return;
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();
        bool isEnabled = true; // Standardwert
        if (userDoc.exists && userDoc.data() != null) {
          var data = userDoc.data() as Map<String, dynamic>;
          isEnabled = data['userNotificationsEnabled'] ?? true;
        }
        if (mounted) {
          setState(() {
            userNotificationsEnabled = isEnabled;
          });
        }
      } catch (e) {
        print("Fehler beim Laden der Benachrichtigungseinstellung: $e");
        if (mounted) {
          setState(() {
            userNotificationsEnabled = true;
          });
        }
      } finally {
        if (mounted) {
          setState(() {});
        }
      }
    } else {
      if (mounted) {
        setState(() {
          userNotificationsEnabled = true;
        });
      }
    }
  }

  Future<void> _loadProfileImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _profileImageUrl = userDoc["photoUrl"];
        });
      }
    }
  }

  /*Future<void> _toggleNotifications(bool value) async {
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
  }*/
  Future<void> _toggleNotifications(bool value) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        'userNotificationsEnabled': value,
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          userNotificationsEnabled = value;
        });
      }

      if (value) {
        AppLogger().info('Settings', 'Versuche Token zu speichern...');
        await NotificationService.saveTokenToFirestore();
      } else {
        AppLogger().info('Settings', 'Lösche Token...');
        await NotificationService.deleteTokenFromFirestore();
      }

      AppSnackBar.success(context,
          'Benachrichtigungen ${value ? 'aktiviert' : 'deaktiviert'}.');
    } catch (e) {
      AppLogger().error(
          'Settings', 'Fehler beim Umschalten der Benachrichtigungen',
          error: e);
      AppSnackBar.error(context, 'Fehler beim Speichern der Einstellung.');
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
    if (user != null && _userNameController.text.isNotEmpty) {
      bool userNameExists =
          await checkIfUsernameExists(_userNameController.text.trim());
      if (userNameExists) {
        _showConfirmationPopup("Benutzername ist vergeben", false);
        return;
      }
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({
        "name": _userNameController.text.trim(),
        "lowercaseName": _userNameController.text.trim().toLowerCase(),
      });

      await FirestoreService()
          .updateUsernameInReviews(user.uid, _userNameController.text.trim());

      widget.onUsernameChanged();
      _showConfirmationPopup("Benutzername aktualisiert", true);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String filePath = "profile_images/${user.uid}.jpg";
      UploadTask uploadTask =
          FirebaseStorage.instance.ref().child(filePath).putFile(file);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({
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
                  leading: Icon(
                      Platform.isIOS ? CupertinoIcons.camera : Icons.camera_alt,
                      color: Theme.of(context).colorScheme.primary),
                  title: Text("Kamera verwenden"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(Platform.isIOS
                      ? CupertinoIcons.collections
                      : Icons.photo_library),
                  title: Text("Galerie öffnen"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                )
              ],
            ),
          );
        });
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
              passed
                  ? Icon(
                      Platform.isIOS
                          ? CupertinoIcons.check_mark_circled
                          : Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 40)
                  : Icon(
                      Platform.isIOS
                          ? CupertinoIcons.xmark_circle
                          : Icons.close_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 40),
              SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
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
    if (mounted) context.go('/login');
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Konto löschen"),
        content: Text(
            "Bist du sicher, dass du dein Konto dauerhaft löschen möchtest?"),
        alignment: Alignment.center,
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
      if (mounted) context.go('/login');
    } on FirebaseException catch (e) {
      print("Fehler beim Löschen des Accounts: $e");

      if (e.code == "requires-recent-login") {
        print("Reauthentifizierung erforderlich zum Löschen des Accounts.");
        await _reauthenticateAndDelete();
      } else {
        print("Anderer Fehlercode: ${e.code}");
      }
    } catch (e) {
      print("Unbekannter Fehler beim Löschen des Accounts: $e");
    }
  }

  Future<void> _reauthenticateAndDelete() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final providerId = user.providerData.first.providerId;

    try {
      if (providerId == EmailAuthProvider.PROVIDER_ID) {
        final TextEditingController passwordController =
            TextEditingController();

        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Bitte bestätige deine Identität"),
            content: TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(hintText: "Dein Passwort"),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text("Abbrechen")),
              ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text("Bestätigen & Löschen")),
            ],
          ),
        );

        if (confirmed == true && passwordController.text.isNotEmpty) {
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: passwordController.text,
          );

          await user.reauthenticateWithCredential(credential);
          _deleteAccount();
        }
      } else if (AppleAuthProvider.PROVIDER_ID == providerId) {
        await FirebaseAuth.instance.currentUser
            ?.reauthenticateWithProvider(AppleAuthProvider());
        _deleteAccount();
      } else if (GoogleAuthProvider().providerId == providerId) {
        await FirebaseAuth.instance.currentUser
            ?.reauthenticateWithProvider(GoogleAuthProvider());
        _deleteAccount();
      }
    } catch (e) {
      print("Fehler beim Reauthentifizieren und Löschen des Accounts: $e");
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
          icon: Icon(Icons.adaptive.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Einstellungen",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
                    backgroundImage:
                        _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                            ? ResizeImage(NetworkImage(_profileImageUrl!),
                                height: 420, policy: ResizeImagePolicy.fit)
                            : ResizeImage(
                                AssetImage("assets/icons/default_avatar.png"),
                                height: 420,
                                policy: ResizeImagePolicy.fit) as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        radius: 20,
                        child: Icon(
                            Platform.isIOS
                                ? CupertinoIcons.camera
                                : Icons.camera_alt,
                            color: Colors.white,
                            size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            SwitchListTile.adaptive(
              title: Text("Push-Benachrichtigungen",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              value: userNotificationsEnabled,
              onChanged: _toggleNotifications,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            ListTile(
              title: Text("Geschmacksprofil bearbeiten",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              trailing: Icon(
                  Platform.isIOS ? CupertinoIcons.flame : Icons.restaurant_menu,
                  color: Theme.of(context).colorScheme.onSurface),
              onTap: () => TasteProfileSheet.show(context),
            ),
            ListTile(
              title: Text("Benutzernamen ändern",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              trailing: Icon(
                  Platform.isIOS ? CupertinoIcons.pencil : Icons.edit,
                  color: Theme.of(context).colorScheme.onSurface),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      "Neuen Benutzernamen eingeben",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                    content: TextField(
                      controller: _userNameController,
                      decoration:
                          InputDecoration(hintText: "Neuer Benutzername"),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "Abbrechen",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _updateUsername();
                          Navigator.of(context).pop();
                        },
                        child: Text("Speichern",
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              title:
                  Text("Abmelden", style: TextStyle(color: Colors.redAccent)),
              onTap: _signOut,
            ),
            ListTile(
              title: Text("Konto löschen",
                  style: TextStyle(color: Colors.redAccent)),
              onTap: _confirmDeleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}
