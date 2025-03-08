import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/services/database_service.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DatabaseService dbService = DatabaseService();

  Future<void> followUser(String targetUserId) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    if(currentUserId == targetUserId) return;

    DocumentReference currentUserRef = _db.collection("users").doc(currentUserId);
    DocumentReference targetUserRef = _db.collection("users").doc(targetUserId);

    await currentUserRef.update({
      "following": FieldValue.arrayUnion([targetUserId])
    });
    await targetUserRef.update({
      "followers": FieldValue.arrayUnion([currentUserId])
    });
  }

  Future<void> unfollowUser(String targetUserId) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    if (currentUserId == targetUserId) return;

    DocumentReference currentUserRef = _db.collection("users").doc(currentUserId);
    DocumentReference targetUserRef = _db.collection("users").doc(targetUserId);

    await currentUserRef.update({
      "following": FieldValue.arrayRemove([targetUserId])
    });
    await targetUserRef.update({
      "followers": FieldValue.arrayRemove([currentUserId])
    });
  }

  Future<bool> isFollowingUser(String targetUserId) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc = await _db.collection("users").doc(currentUserId).get();
    List<dynamic> following = (userDoc.data() as Map<String, dynamic>)?["following"] ?? [];
    return following.contains(targetUserId);
  }

  Future<int> getFollowerCount(String userId) async {
    DocumentSnapshot userDoc = await _db.collection("users").doc(userId).get();
    List<dynamic> followers = (userDoc.data() as Map<String, dynamic>)?["followers"] ?? [];
    return followers.length;
  }

  Future<int> getFollowingCount(String userId) async {
    DocumentSnapshot userDoc = await _db.collection("users").doc(userId).get();
    List<dynamic> following = (userDoc.data() as Map<String, dynamic>)?["following"] ?? [];
    return following.length;
  }

  Future<List<String>> getFollowers(String userId) async {
    DocumentSnapshot userDoc = await _db.collection("users").doc(userId).get();
    return (userDoc.data() as Map<String, dynamic>)?["followers"]?.cast<String>() ?? [];
  }

  Future<List<String>> getFollowing(String userId) async {
    DocumentSnapshot userDoc = await _db.collection("users").doc(userId).get();
    return (userDoc.data() as Map<String, dynamic>)?["following"]?.cast<String>() ?? [];
  }

  Future<List<Map<String, dynamic>>> getMarkers() async {
    return await dbService.getAllRestaurants();
  }

  Future<List<Map<String, dynamic>>> getMarkersInBounds(LatLngBounds bounds) async {
    return await dbService.getRestaurantsInBounds(
      bounds.southwest.latitude,
      bounds.southwest.longitude,
      bounds.northeast.latitude,
      bounds.northeast.longitude,
    );
  }

  Future<Map<String, dynamic>?> fetchPlaceDetails(String placeId) async {
    DocumentSnapshot doc = await _db.collection('markers').doc(placeId).get();

    if(doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> fetchAndStoreRestaurants() async {
    print("⚡ Lade Daten aus Firestore und speichere sie in SQLite...");
    QuerySnapshot querySnapshot = await _db.collection('markers').get();

    await dbService.clearDatabase();

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      await dbService.insertRestaurant({
        "id": data["id"],
        "name": data["name"],
        "description": data["description"] ?? "Keine Beschreibung verfügbar",
        "latitude": data["location"].latitude,
        "longitude": data["location"].longitude,
        "icon": data["icon"] ?? "",
        "rating": double.tryParse(data["rating"].toString()) ?? 0.0,
        "openingHours": data["openingHours"] ?? "Keine Öffnungszeiten",
      });
    }

    print("✅ Firestore-Daten wurden in SQLite gespeichert!");
  }
}

class FollowButton extends StatefulWidget {
  final String targetUserId;

  FollowButton({required this.targetUserId});

  @override
  _FollowButtonState createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool isFollowing = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _checkFollowingStatus();
  }

  Future<void> _checkFollowingStatus() async {
    bool following = await _firestoreService.isFollowingUser(widget.targetUserId);
    setState(() {
      isFollowing = following;
    });
  }

  Future<void> _toggleFollow() async {
    if(isFollowing) {
      await _firestoreService.unfollowUser(widget.targetUserId);
    } else {
      await _firestoreService.followUser(widget.targetUserId);
    }
    setState(() {
      isFollowing = !isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _toggleFollow,
      child: Text(isFollowing ? "Entfolgen" : "Folgen"),
      style: ElevatedButton.styleFrom(
        backgroundColor: isFollowing ? Colors.grey : Colors.blue,
        foregroundColor: Colors.white
      ),
    );
  }
}