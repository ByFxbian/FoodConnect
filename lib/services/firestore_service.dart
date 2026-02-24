// ignore: unused_import
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:foodconnect/services/database_service.dart';
import 'package:foodconnect/services/noti_service.dart';
// ignore: unused_import
import 'package:foodconnect/services/notification_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'package:platform_maps_flutter/platform_maps_flutter.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DatabaseService dbService = DatabaseService();

  final NotiService _notiLogger = NotiService();

  Future<void> followUser(String targetUserId) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    if (currentUserId == targetUserId) return;

    DocumentSnapshot userDoc =
        await _db.collection("users").doc(currentUserId).get();

    bool emailVerified = userDoc["emailVerified"] ?? false;
    if (!emailVerified) {
      throw FirebaseException(
        plugin: "Firestore",
        message:
            "Bitte bestätige zuerst deine E-Mail-Adresse, bevor du Nutzern folgen kannst!",
      );
    }

    final actorData = userDoc.data() as Map<String, dynamic>;
    String actorName = actorData["name"] ?? "Ein Nutzer";
    String actorImageUrl = actorData["photoUrl"] ?? "";

    final batch = _db.batch();

    // Add to current user's following list
    batch.set(
      _db
          .collection("users")
          .doc(currentUserId)
          .collection("following")
          .doc(targetUserId),
      {'followedAt': FieldValue.serverTimestamp()},
    );

    // Add to target user's followers list
    batch.set(
      _db
          .collection("users")
          .doc(targetUserId)
          .collection("followers")
          .doc(currentUserId),
      {'followedAt': FieldValue.serverTimestamp()},
    );

    // Increment denormalized counters
    batch.update(
      _db.collection("users").doc(currentUserId),
      {'followingCount': FieldValue.increment(1)},
    );
    batch.update(
      _db.collection("users").doc(targetUserId),
      {'followerCount': FieldValue.increment(1)},
    );

    await batch.commit();

    // Send notification (outside batch — non-critical)
    await _notiLogger.logNotificationInDatabase(
        title: "$actorName folgt dir jetzt!",
        body: "Tippe, um sein/ihr Profil zu besuchen.",
        recipientUserId: targetUserId,
        type: 'follow',
        actorId: currentUserId,
        actorName: actorName,
        actorImageUrl: actorImageUrl);
  }

  Future<void> unfollowUser(String targetUserId) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    if (currentUserId == targetUserId) return;

    final batch = _db.batch();

    // Remove from current user's following list
    batch.delete(
      _db
          .collection("users")
          .doc(currentUserId)
          .collection("following")
          .doc(targetUserId),
    );

    // Remove from target user's followers list
    batch.delete(
      _db
          .collection("users")
          .doc(targetUserId)
          .collection("followers")
          .doc(currentUserId),
    );

    // Decrement denormalized counters
    batch.update(
      _db.collection("users").doc(currentUserId),
      {'followingCount': FieldValue.increment(-1)},
    );
    batch.update(
      _db.collection("users").doc(targetUserId),
      {'followerCount': FieldValue.increment(-1)},
    );

    await batch.commit();
  }

  Future<void> updateEmailVerificationStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      bool emailVerified = user.emailVerified;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({
        "emailVerified": emailVerified,
      });
    }
  }

  Future<bool> isFollowingUser(String targetUserId) async {
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Check if the current user is following the target user by checking for a document in the following subcollection.
    final followingDoc = await _db
        .collection("users")
        .doc(currentUserId)
        .collection("following")
        .doc(targetUserId)
        .get();

    return followingDoc.exists;
  }

  Future<int> getFollowerCount(String userId) async {
    final userDoc = await _db.collection("users").doc(userId).get();
    final data = userDoc.data();
    if (data != null && data['followerCount'] != null) {
      return (data['followerCount'] as num).toInt();
    }
    // Fallback for un-migrated users
    final followersQuery =
        await _db.collection("users").doc(userId).collection("followers").get();
    return followersQuery.docs.length;
  }

  Future<int> getFollowingCount(String userId) async {
    final userDoc = await _db.collection("users").doc(userId).get();
    final data = userDoc.data();
    if (data != null && data['followingCount'] != null) {
      return (data['followingCount'] as num).toInt();
    }
    // Fallback for un-migrated users
    final followingQuery =
        await _db.collection("users").doc(userId).collection("following").get();
    return followingQuery.docs.length;
  }

  Future<List<Map<String, dynamic>>> getMarkers() async {
    return await dbService.getAllRestaurants();
  }

  Future<List<Map<String, dynamic>>> getMarkersInBounds(
      LatLngBounds bounds) async {
    return await dbService.getRestaurantsInBounds(
      bounds.southwest.latitude,
      bounds.southwest.longitude,
      bounds.northeast.latitude,
      bounds.northeast.longitude,
    );
  }

  Future<Map<String, dynamic>?> fetchPlaceDetails(String placeId) async {
    DocumentSnapshot doc = await _db.collection('markers').doc(placeId).get();

    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getUserReviews(String userId) async {
    QuerySnapshot querySnapshot = await _db
        .collection('restaurantReviews')
        .where('userId', isEqualTo: userId)
        .get();

    List<Map<String, dynamic>> reviews = [];

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> reviewData = doc.data() as Map<String, dynamic>;
      DocumentSnapshot restaurantDoc =
          await _db.collection('markers').doc(reviewData['restaurantId']).get();
      if (restaurantDoc.exists) {
        reviewData['restaurantName'] =
            restaurantDoc['name'] ?? "Unbekanntes Restaurant";
      } else {
        reviewData['restaurantName'] = "Unbekanntes Restaurant";
      }
      reviews.add(reviewData);
    }
    return reviews;
  }

  Future<void> fetchAndStoreRestaurants() async {
    print("⚡ Lade Daten aus Firestore und speichere sie in SQLite...");
    QuerySnapshot querySnapshot =
        await _db.collection('restaurantDetails').get();

    await dbService.clearDatabase();

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      await dbService.insertRestaurant({
        "id": data["id"],
        "name": data["name"],
        "latitude": data["location"].latitude,
        "longitude": data["location"].longitude,
        "icon": data["icon"] ?? "",
        "rating": double.tryParse(data["rating"].toString()) ?? 0.0,
        "priceLevel": data["priceLevel"],
        "cuisines": data["cuisines"],
        "openingHours": data["openingHours"] ?? [],
      });

      await dbService.setRestaurantRating(
          data["id"], double.tryParse(data["rating"].toString()) ?? 0.0);
    }

    print("✅ Firestore-Daten wurden in SQLite gespeichert!");
  }

  Future<Map<String, dynamic>?> fetchRestaurantDetails(
      String restaurantId) async {
    DocumentSnapshot doc =
        await _db.collection("restaurantDetails").doc(restaurantId).get();

    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }

  Future<bool> hasUserReviewed(String restaurantId, String userId) async {
    QuerySnapshot querySnapshot = await _db
        .collection('restaurantReviews')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('userId', isEqualTo: userId)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> updateUsernameInReviews(
      String userId, String newUsername) async {
    QuerySnapshot querySnapshot = await _db
        .collection("restaurantReviews")
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in querySnapshot.docs) {
      doc.reference.update({"userName": newUsername});
    }
  }

  Future<void> addReview(String restaurantId, double rating, String comment,
      String userId, String userName, String userProfileUrl) async {
    if (await hasUserReviewed(restaurantId, userId)) {
      print("⚠️ Nutzer hat dieses Restaurant bereits bewertet.");
      return;
    }

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection("users").doc(userId).get();

    bool emailVerified = userDoc["emailVerified"] ?? false;
    if (!emailVerified) {
      throw FirebaseException(
        plugin: "Firestore",
        message:
            "Bitte bestätige zuerst deine E-Mail-Adresse bevor du bewerten kannst!",
      );
    }

    await _db.collection('restaurantReviews').add({
      'restaurantId': restaurantId,
      'rating': rating,
      'comment': comment,
      'userId': userId,
      'userName': userName,
      'userProfileUrl': userProfileUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });

    Map<String, dynamic>? restaurantData =
        await dbService.getRestaurantById(restaurantId);
    String restaurantName = restaurantData?["name"] ?? "ein Restaurant";

    QuerySnapshot followerSnapshot =
        await _db.collection("users").doc(userId).collection("followers").get();
    for (var doc in followerSnapshot.docs) {
      String followerId = doc.id;
      /* NotificationService.sendNotification(
        recipientUserId: followerId,
        title: "$userName hat ein Restaurant bewertet!",
        body: "Es wurde mit $rating Sternen bewertet.",
      );*/
      /*NotiService().showNotification(
        id: Random().nextInt(100000000),
        title: "$userName hat ein Restaurant bewertet!",
        body: "Es wurde mit $rating Sternen bewertet.",
        recipientUserId: followerId
      );*/
      await _notiLogger.logNotificationInDatabase(
          title: "$userName hat ein $restaurantName bewertet!",
          body: "Es wurde mit $rating Sternen bewertet.",
          recipientUserId: followerId,
          type: 'review',
          actorId: userId,
          actorName: userName,
          actorImageUrl: userProfileUrl,
          relevantId: restaurantId);
    }
  }

  Future<int> getUserReviewCount(String userId) async {
    if (userId.isEmpty) return 0;
    try {
      AggregateQuerySnapshot snapshot = await _db
          .collection('restaurantReviews')
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      print("Review count for $userId: ${snapshot.count}");
      return snapshot.count ?? 0;
    } catch (e) {
      print("Fehler beim Zählen der User Reviews für $userId: $e");
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getReviewsForRestaurant(
      String restaurantId) async {
    QuerySnapshot querySnapshot = await _db
        .collection('restaurantReviews')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();
    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<double> calculateAverageRating(String restaurantId) async {
    List<Map<String, dynamic>> reviews =
        await getReviewsForRestaurant(restaurantId);
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

  // --- List Management ---

  Future<List<Map<String, dynamic>>> getUserLists(String userId,
      {bool onlyPublic = false}) async {
    Query query = _db.collection('users').doc(userId).collection('lists');

    if (onlyPublic) {
      query = query.where('isPublic', isEqualTo: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    QuerySnapshot querySnapshot = await query.get();

    final results = querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    // Client-side sort for onlyPublic (avoids composite index)
    if (onlyPublic) {
      results.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
    }

    return results;
  }

  Stream<List<Map<String, dynamic>>> streamUserLists(String userId,
      {bool onlyPublic = false}) {
    Query query = _db.collection('users').doc(userId).collection('lists');

    if (onlyPublic) {
      query = query.where('isPublic', isEqualTo: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    return query.snapshots().map(
      (snapshot) {
        final results = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();

        // Client-side sort for onlyPublic (avoids composite index)
        if (onlyPublic) {
          results.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
        }

        return results;
      },
    );
  }

  Future<void> createList(String userId, String listName,
      {List<String> restaurantIds = const []}) async {
    await _db.collection('users').doc(userId).collection('lists').add({
      'name': listName,
      'restaurantIds': restaurantIds,
      'isPublic': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addRestaurantToList(
      String userId, String listId, String restaurantId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listId)
        .update({
      'restaurantIds': FieldValue.arrayUnion([restaurantId]),
    });
  }

  Future<void> removeRestaurantFromList(
      String userId, String listId, String restaurantId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listId)
        .update({
      'restaurantIds': FieldValue.arrayRemove([restaurantId]),
    });
  }

  Future<void> renameList(String userId, String listId, String newName) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listId)
        .update({'name': newName});
  }

  Future<void> toggleListVisibility(
      String userId, String listId, bool isPublic) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listId)
        .update({'isPublic': isPublic});
  }

  Future<void> deleteList(String userId, String listId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listId)
        .delete();
  }

  Future<void> updateListCoverUrl(
      String userId, String listId, String coverUrl) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listId)
        .update({'coverUrl': coverUrl});
  }
}
