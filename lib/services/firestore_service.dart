import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodconnect/services/database_service.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DatabaseService dbService = DatabaseService();

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