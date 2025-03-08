

import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import hinzugefügt
import 'package:flutter/services.dart';
import 'package:foodconnect/main.dart';
import 'package:foodconnect/screens/profile_screen.dart';
import 'package:foodconnect/screens/user_profile_screen.dart';
import 'package:foodconnect/services/database_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:foodconnect/services/firestore_service.dart'; // Import hinzugefügt
import 'package:foodconnect/widgets/rating_dialog.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

class MarkerManager {
  static final MarkerManager _instance = MarkerManager._internal();
  factory MarkerManager() => _instance;
  MarkerManager._internal();

  final DatabaseService databaseService = DatabaseService();
  final FirestoreService firestoreService = FirestoreService(); // Instanz hinzugefügt
  Set<Marker> markers = {};
  BitmapDescriptor? customIcon;
  BitmapDescriptor? highlightedIcon;
  String? selectedMarkerId;
  Map<String, dynamic>? userData;

  Future<void> _loadCustomIcon() async {
    final ByteData data = await rootBundle.load('assets/icons/mapicon.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes, targetWidth: 115);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ByteData? byteData = await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);

    if(byteData != null) {
      customIcon = BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
    }

    final ByteData highlightData = await rootBundle.load('assets/icons/mapicon.png');
    final Uint8List highlightBytes = highlightData.buffer.asUint8List();
    final ui.Codec highlightCodec = await ui.instantiateImageCodec(highlightBytes, targetWidth: 140);
    final ui.FrameInfo highlightFrame = await highlightCodec.getNextFrame();
    final ByteData? highlightByteData = await highlightFrame.image.toByteData(format: ui.ImageByteFormat.png);

    if (highlightByteData != null) {
      highlightedIcon = BitmapDescriptor.fromBytes(highlightByteData.buffer.asUint8List());
    }
  }

  Future<void> loadMarkers() async {
    await _loadCustomIcon();

    List<Map<String, dynamic>> markerData = await databaseService.getAllRestaurants();
    Set<Marker> newMarkers = {};

    for (var data in markerData) {
      Marker marker = Marker(
         markerId: MarkerId(data['id'] ?? 'unknown'),
        position: LatLng(data['latitude'], data['longitude']),
        icon: customIcon!, // Wird später angepasst
        onTap: () {
          final ctx = navigatorKey.currentContext;
          if(ctx == null) return;
          highlightMarker(data['id']);
          showMarkerPanel(ctx, data);
        },
      );

      newMarkers.add(marker);
    }

    markers = newMarkers;
  }

  void highlightMarker(String markerId) {
    selectedMarkerId = markerId;
    Set<Marker> updatedMarkers = markers.map((marker) {
      return marker.copyWith(
        iconParam: marker.markerId.value == markerId ? highlightedIcon : customIcon,
      );
    }).toSet();
    markers = updatedMarkers;
  }

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.street}, ${place.locality}, ${place.country}";
      }
      return "Adresse nicht gefunden";
    } catch (e) {
      print("Fehler beim Abrufen der Adresse: $e");
      return "Adresse nicht verfügbar";
    }
  }

  Future<void> _loadUserData(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .get();

    if (userDoc.exists) {
      userData = userDoc.data() as Map<String, dynamic>;
    } else {
      userData = {};
    }
  }

  void showMarkerPanel(BuildContext context, Map<String, dynamic> restaurantData) async {
    String address = await getAddressFromLatLng(restaurantData['latitude'], restaurantData['longitude']);

        // Vorhandenes Rating aus Firestore holen
        Map<String, dynamic>? markerDetails = await firestoreService.fetchPlaceDetails(restaurantData['id']);
        String markerRating = markerDetails?['rating'].toString() ?? "0.0";
        double dmarkerRating = double.parse(markerRating);
        //double dRating = double.parse(markerRating);
        double firestoreRating = dmarkerRating;
    
    //Reviews holen
    List<Map<String, dynamic>> reviews = await firestoreService.getReviewsForRestaurant(restaurantData['id']);
        
        // Durchschnitt berechnen
        double averageRating = await firestoreService.calculateAverageRating(restaurantData['id']);
        
        // Das zusammengezählte Rating berechnen
        double finalRating = reviews.isNotEmpty ? (firestoreRating*0.7 + averageRating*0.3) : firestoreRating;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantData['name'] ?? "Unbekannt",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      address,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset("assets/icons/mapicon.png", height: 100),
                      ),
                    ),
                    SizedBox(height: 16),
                    if (restaurantData['description'] != null) ...[
                      Text(
                        "📌 Beschreibung",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(restaurantData['description'] ?? "", style: TextStyle(fontSize: 16)),
                      SizedBox(height: 16),
                    ],
                    if (restaurantData['openingHours'] != null) ...[
                      Text(
                        "🕒 Öffnungszeiten",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _formatOpeningHours(restaurantData['openingHours']),
                      ),
                      SizedBox(height: 16),
                    ],
                    if (restaurantData['rating'] != null) ...[
                      Text(
                        "⭐ Bewertung",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text("${finalRating.toStringAsFixed(1)} / 5.0", style: TextStyle(fontSize: 16)),
                      ElevatedButton( // Hinzugefügter Button
                        onPressed: () {
                          
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return RatingDialog(
                                restaurantId: restaurantData['id'],
                                onRatingSubmitted: (rating, comment) async { // Callback angepasst
                                  final String userId = FirebaseAuth.instance.currentUser!.uid;
                                  await _loadUserData(userId);
                                  final String userName = userData?['name'] ?? "Unbekannter Nutzer";
                                  final String userProfileUrl = userData?['photoUrl'] ?? "";
                                  await firestoreService.addReview(restaurantData['id'], rating, comment, userId, userName, userProfileUrl);
                                  double newAverageRating = await firestoreService.calculateAverageRating(restaurantData['id']);
                                  await firestoreService.setRestaurantRating(restaurantData['id'], newAverageRating);

                                  if (navigatorKey.currentState?.canPop() ?? false) {
                                    navigatorKey.currentState?.pop();
                                  }
                                  await Future.delayed(Duration(milliseconds: 300));
                                  showMarkerPanel(navigatorKey.currentContext!, restaurantData);
                                },
                              );
                            },
                          );
                        },
                        child: Text("Bewerten"),
                      ),
                       SizedBox(height: 16),
                      // Hier die Reviews anzeigen
                      if (reviews.isNotEmpty) ...[
                        Text(
                          "Reviews:",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: reviews.map((review) => 
                            ListTile(
                              leading: CircleAvatar(
                                backgroundImage: review['userProfileUrl'] != null && review['userProfileUrl'].isNotEmpty 
                                  ? NetworkImage(review['userProfileUrl']) 
                                  : null,
                                child: review['userProfileUrl'] == null || review['userProfileUrl'].isEmpty 
                                  ? Icon(Icons.person) 
                                  : null,
                              ),
                                title: Text(review['userName'] ?? 'Unbekannt'),
                              subtitle: Text("- ${review['rating']} ⭐: ${review['comment']}"),
                              onTap: () {
                                _navigateToUserProfile(review['userId'], context);
                              },
                            )
                          ).toList(),
                        ),
                      ],
                    ],
                  ]
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      selectedMarkerId = null;
      loadMarkers();
    });
  }

  void _navigateToUserProfile(String userId, BuildContext context) async {
    if(userId == FirebaseAuth.instance.currentUser!.uid) {
      await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(),
      ));
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(userId: userId),
        ),
      );
    }
  }

  static List<Widget> _formatOpeningHours(String openingHours) {
    final Map<String, String> daysMap = {
      "Monday": "Montag",
      "Tuesday": "Dienstag",
      "Wednesday": "Mittwoch",
      "Thursday": "Donnerstag",
      "Friday": "Freitag",
      "Saturday": "Samstag",
      "Sunday": "Sonntag"
    };

    List<Widget> formattedHours = [];
    List<String> lines = openingHours.split(" | ");
    for(var line in lines) {
      List<String> parts = line.split(": ");
      if(parts.length == 2) {
        String day = daysMap[parts[0]] ?? parts[0];
        String time = _convertTo24HourFormat(parts[1]);

        if (time.toLowerCase().contains("open 24 hours")) {
          time = "Durchgehend geöffnet";
        } else if (time.toLowerCase().contains("closed")) {
          time = "Geschlossen";
        }

        formattedHours.add(Text("$day: $time", style: TextStyle(fontSize: 16)));
      } else {
        formattedHours.add(Text(line, style: TextStyle(fontSize: 16)));
      }
    }
    return formattedHours;
  }

  static String _convertTo24HourFormat(String timeRange) {
    return timeRange.replaceAllMapped(
      RegExp(r'(\d{1,2}):(\d{2})\s?(AM|PM)\s?[–-]\s?(\d{1,2}):(\d{2})\s?(AM|PM)'),
      (Match m) {
        int startHour = int.parse(m[1]!);
        String startMinute = m[2]!;
        String startPeriod = m[3]!;

        int endHour = int.parse(m[4]!);
        String endMinute = m[5]!;
        String endPeriod = m[6]!;

        // Umwandlung der Startzeit
        if (startPeriod == "PM" && startHour != 12) {
          startHour += 12;
        } else if (startPeriod == "AM" && startHour == 12) {
          startHour = 0;
        }

        // Umwandlung der Endzeit
        if (endPeriod == "PM" && endHour != 12) {
          endHour += 12;
        } else if (endPeriod == "AM" && endHour == 12) {
          endHour = 0;
        }

        return "${startHour.toString().padLeft(2, '0')}:$startMinute - ${endHour.toString().padLeft(2, '0')}:$endMinute";
      },
    );
  }

}