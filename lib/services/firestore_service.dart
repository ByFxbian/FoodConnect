import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getMarkers() async {
    QuerySnapshot querySnapshot = await _db.collection('markers').get();
    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getMarkersInBounds(LatLngBounds bounds) async {
    QuerySnapshot querySnapshot = await _db
      .collection("markers")
      .where('location', isGreaterThan: GeoPoint(bounds.southwest.latitude, bounds.southwest.longitude))
      .where('location', isLessThan: GeoPoint(bounds.northeast.latitude, bounds.northeast.longitude))
      .get();

    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> fetchPlaceDetails(String placeId) async {
    const String apiKey = "AIzaSyAdoiyJg_cGgmKrrsLJeBxsqcWXf0knLqA";
    final response = await http.get(Uri.parse(
      "https://maps.googleapis.com/maps/api/place/details/json?"
      "place_id=$placeId"
      "&fields=name,formatted_address,opening_hours,editorial_summary,website,formatted_phone_number,rating"
      "&key=$apiKey"
    ));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["status"] == "OK") {
        return {
          "description": data["result"]["editorial_summary"]?["overview"] ?? "Keine Beschreibung verfügbar",
          "openingHours": data["result"]["opening_hours"]?["weekday_text"]?.join(", ") ?? "Unbekannt",
          "phone": data["result"]["formatted_phone_number"] ?? "Keine Telefonnummer",
          "website": data["result"]["website"] ?? "Keine Website",
        };
      }
    }
    return {};
  }

  Future<void> fetchAndStoreRestaurants() async {
    const String apiKey = "AIzaSyAdoiyJg_cGgmKrrsLJeBxsqcWXf0knLqA";
    const String location = "48.210033,16.363449";
    const String radius = "20000";
    const String type = "restaurant";

    String nextPageToken = "";
    int totalFetched = 0;
    int maxRequests = 5;// Wir machen max. 3 API Requests (60 Restaurants)

    do {
      final response = await http.get(Uri.parse(
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
        "location=$location"
        "&radius=$radius"
        "&type=$type"
        "&key=$apiKey"
        "${nextPageToken.isNotEmpty ? "&pagetoken=$nextPageToken" : ""}"
      ));

      print("Response: $response");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data["results"];
        
        for (var place in results) {
          String placeId = place["place_id"];

          Map<String, dynamic> details = await fetchPlaceDetails(placeId);

          final Map<String, dynamic> restaurantData = {
            "id": placeId,
            "name": place["name"],
            "location": GeoPoint(
              place["geometry"]["location"]["lat"],
              place["geometry"]["location"]["lng"]
            ),
            "icon": "mapicon.png", // Falls nicht in API enthalten
            "description": details["description"],
            "openingHours": details["openingHours"],
            "phone": details["phone"],
            "website": details["website"],
            "rating": place["rating"]?.toString() ?? "0.0",
          };

           if (place['types'] != null && !place['types'].contains('restaurant')) {
              print("Überspringe ${place['name']}, kein Restaurant.");
              continue;
            }

          // Speichere das Restaurant, falls es noch nicht existiert
          final docRef = FirebaseFirestore.instance.collection("markers").doc(place["place_id"]);
          final docSnap = await docRef.get();
          if (!docSnap.exists) {
            await docRef.set(restaurantData);
            totalFetched++;
          }
        }

        // Nächste Seite abrufen?
        nextPageToken = data["next_page_token"] ?? "";
        await Future.delayed(Duration(seconds: 2)); // Google braucht kurz Zeit, um next_page_token zu generieren
      } else {
        print("Fehler bei der Google Places API: ${response.body}");
        break;
      }

      maxRequests--;
    } while (nextPageToken.isNotEmpty && maxRequests > 0);

    print("Insgesamt $totalFetched neue Restaurants hinzugefügt.");
  }
}