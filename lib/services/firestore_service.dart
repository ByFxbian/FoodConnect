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

    // Add to current user's following list
    await _db
        .collection("users")
        .doc(currentUserId)
        .collection("following")
        .doc(targetUserId) 
        .set({});
    
    // Add to target user's followers list
    await _db
        .collection("users")
        .doc(targetUserId)
        .collection("followers")
        .doc(currentUserId)
        .set({});
  }

  Future<void> unfollowUser(String targetUserId) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    if (currentUserId == targetUserId) return;

    // Remove from current user's following list
    await _db.collection("users").doc(currentUserId).collection("following").doc(targetUserId).delete();
    
    // Remove from target user's followers list
    await _db.collection("users").doc(targetUserId).collection("followers").doc(currentUserId).delete();
  }

  Future<bool> isFollowingUser(String targetUserId) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    
    // Check if the current user is following the target user by checking for a document in the following subcollection.
    final followingDoc = await 
    _db
        .collection("users")
        .doc(currentUserId)
        .collection("following")
        .doc(targetUserId)
        .get();

    return followingDoc.exists;
  }

  Future<int> getFollowerCount(String userId) async {
    final followersQuery = await _db.collection("users").doc(userId).collection("followers").get();
    return followersQuery.docs.length;
  }

  Future<int> getFollowingCount(String userId) async {
    final followingQuery = await _db.collection("users").doc(userId).collection("following").get();
    return followingQuery.docs.length;
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
        "reviews": []
      });

      await dbService.setRestaurantRating(data["id"], double.tryParse(data["rating"].toString()) ?? 0.0);
    }

    print("✅ Firestore-Daten wurden in SQLite gespeichert!");
  }

  Future<bool> hasUserReviewed(String restaurantId, String userId) async {
    QuerySnapshot querySnapshot = await _db
        .collection('restaurantReviews')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('userId', isEqualTo: userId)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> addReview(String restaurantId, double rating, String comment, String userId, String userName, String userProfileUrl) async {
    if (await hasUserReviewed(restaurantId, userId)) {
      print("⚠️ Nutzer hat dieses Restaurant bereits bewertet.");
      return;
    }
    await _db.collection('restaurantReviews').add({
      'restaurantId': restaurantId,
      'rating': rating,
      'comment': comment,
      'userId': userId,
      'userName': userName,
      'userProfileUrl': userProfileUrl,
    });
  }

  Future<List<Map<String, dynamic>>> getReviewsForRestaurant(String restaurantId) async {
    QuerySnapshot querySnapshot = await _db
        .collection('restaurantReviews')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();
    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<double> calculateAverageRating(String restaurantId) async {
    List<Map<String, dynamic>> reviews = await getReviewsForRestaurant(restaurantId);
    if (reviews.isEmpty) return 0.0;
    double sum = 0;
    for (var review in reviews) {
      sum += review['rating'];
    }
    return sum / reviews.length;
  }

  Future<void> setRestaurantRating(String restaurantId, double rating) async {
    await dbService.setRestaurantRating(restaurantId, rating);
  }
}

class FollowButton extends StatefulWidget {
  final String targetUserId;

  // ignore: use_super_parameters
  FollowButton({required this.targetUserId, Key? key}) : super(key: key);

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
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isFollowing ? Colors.grey[300] : Colors.blue,
      ),
      child: TextButton(
        onPressed: _toggleFollow,
        child: Text(
          isFollowing ? "Entfolgt" : "Folgen",
          style: TextStyle(
            color: isFollowing ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}