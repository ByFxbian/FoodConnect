

// ignore_for_file: unused_local_variable

import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import hinzugefügt
import 'package:flutter/services.dart';
import 'package:foodconnect/main.dart';
import 'package:foodconnect/screens/main_screen.dart';
import 'package:foodconnect/screens/user_profile_screen.dart';
import 'package:foodconnect/services/database_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:foodconnect/services/firestore_service.dart'; // Import hinzugefügt
import 'package:foodconnect/widgets/rating_dialog.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:timeago/timeago.dart' as timeago;

class MarkerManager {
  static final MarkerManager _instance = MarkerManager._internal();
  factory MarkerManager() => _instance;
  MarkerManager._internal();

  BitmapDescriptor? customIcon;
  BitmapDescriptor? highlightedIcon;

  Future<void> loadCustomIcons() async {
    if(customIcon != null) return;

    try {
      customIcon = await _bitmapDescriptorFromAssetBytes(
        'assets/icons/mapicon.png',
        50
      );

      highlightedIcon = await _bitmapDescriptorFromAssetBytes(
        'assets/icons/mapicon.png',
        70
      );
    } catch (e) {
      print("Fehler beim Laden der Icons: $e");
    }
  }

  Future<BitmapDescriptor> _bitmapDescriptorFromAssetBytes(String path, int width) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData = await fi.image.toByteData(format: ui.ImageByteFormat.png);

    if(byteData == null) throw Exception("Bild konnte nicht konvertiert werden.");

    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  /*final DatabaseService databaseService = DatabaseService();
  final FirestoreService firestoreService = FirestoreService(); // Instanz hinzugefügt
  Set<Marker> markers = {};

  String? selectedMarkerId;
  Map<String, dynamic>? userData;
  bool isPanelOpen = false;

  Future<void> _loadCustomIcon() async {
    if(customIcon != null && highlightedIcon != null) return;

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
        icon: customIcon!,
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
    if(isPanelOpen || navigatorKey.currentContext == null) return;
    if(selectedMarkerId == restaurantData['id']) return;

    isPanelOpen = true;

    selectedMarkerId = restaurantData['id'];

    //Map<String, dynamic>? details = await firestoreService.fetchRestaurantDetails(restaurantData['id']);
    //String address = await getAddressFromLatLng(restaurantData['latitude'], restaurantData['longitude']);
    //Map<String, dynamic>? markerDetails = await firestoreService.fetchPlaceDetails(restaurantData['id']);
    //double finalRating = double.tryParse(markerDetails?['rating'].toString() ?? "0.0") ?? 0.0;
    //List<Map<String, dynamic>> reviews = await firestoreService.getReviewsForRestaurant(restaurantData['id']);
    //double averageRating = await firestoreService.calculateAverageRating(restaurantData['id']);
    //if (reviews.isNotEmpty) {
    //  finalRating = (finalRating * 0.7 + averageRating * 0.3);
    //} 

    /*if(navigatorKey.currentContext == null) {
      isPanelOpen = false;
      return;
    }*/

    showModalBottomSheet(
      context: navigatorKey.currentContext!,
      isScrollControlled: true,
      backgroundColor: Theme.of(navigatorKey.currentContext!).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _MarkerPanelContent(restaurantData: restaurantData);
      }
      
      /*(context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            // ignore: sized_box_for_whitespace
            return Container(
              width: double.infinity,
              child: SingleChildScrollView(
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
                    Text(address, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    SizedBox(height: 16),
                    if (details?['priceLevel'] != null) ...[
                      Text("💰 Preisniveau", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(details?['priceLevel'] ?? "", style: TextStyle(fontSize: 16)),
                      SizedBox(height: 8),
                    ],
                    if (details?['description'] != null) ...[
                      Text("📌 Beschreibung", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(details?['description'] ?? "", style: TextStyle(fontSize: 16)),
                      SizedBox(height: 16),
                    ],
                    if (details?['openingHours'] != null) ...[
                      Text("🕒 Öffnungszeiten", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: _formatOpeningHours(details?['openingHours'])),
                      SizedBox(height: 16),
                    ],
                    if (details?['cuisines'] is List && (details?['cuisines'] as List).isNotEmpty) ...[
                      Text("🍽️ Küche", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: _formatLists(details?["cuisines"])),
                      SizedBox(height: 8),
                    ],
                    if (details?['dietaryRestrictions'] is List && (details?['dietaryRestrictions'] as List).isNotEmpty) ...[
                      Text("🥦 Ernährungsweisen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: _formatLists(details?["dietaryRestrictions"])),
                      SizedBox(height: 8),
                    ],
                    if (details?['mealTypes'] is List && (details?['mealTypes'] as List).isNotEmpty) ...[
                      Text("🍽️ Mahlzeiten", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: _formatLists(details?["mealTypes"])),
                      SizedBox(height: 8),
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
              )
            );
          },
        );
      }, */
    ).whenComplete(() {
      selectedMarkerId = null;
      isPanelOpen = false;
    });
  }

  void _navigateToUserProfile(String userId, BuildContext context) async {
    if(userId == FirebaseAuth.instance.currentUser!.uid) {
      await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          initialPage: 2,
        ),
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

  static List<Widget> _formatOpeningHours(dynamic openingHours) {
    if (openingHours is! List<dynamic>) {
      print("⚠️ Fehler: openingHours hat den falschen Typ (${openingHours.runtimeType}). Setze auf leer.");
      return [Text("Keine Öffnungszeiten verfügbar", style: TextStyle(fontSize: 16))];
    }

    List<String> hoursList = openingHours.map((e) => e.toString()).toList();
    return hoursList.map((entry) => Text(entry, style: TextStyle(fontSize: 16))).toList();
  }

  static List<Widget> _formatLists(dynamic list) {
    if(list is! List<dynamic>) {
      return [Text("Keine Informationen verfügbar", style: TextStyle(fontSize: 16))];
    }

    List<String> stringList = list.map((e) => e.toString()).toList();
    return stringList.map((entry) => Text(entry, style: TextStyle(fontSize: 16))).toList();
  }

}

class _MarkerPanelContent extends StatefulWidget {
  final Map<String, dynamic> restaurantData;

  final FirestoreService firestoreService = FirestoreService();
  final MarkerManager markerManager = MarkerManager();

  _MarkerPanelContent({required this.restaurantData});

  @override
  __MarkerPanelContentState createState() => __MarkerPanelContentState();
}

class __MarkerPanelContentState extends State<_MarkerPanelContent> {
  bool _isLoading = true;
  Map<String, dynamic>? _details;
  String? _address;
  List<Map<String, dynamic>> _reviews = [];
  double _finalRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final detailsFuture = widget.firestoreService.fetchRestaurantDetails(widget.restaurantData['id']);
      final addressFuture = widget.markerManager.getAddressFromLatLng(widget.restaurantData['latitude'], widget.restaurantData['longitude']);
      final reviewsFuture = widget.firestoreService.getReviewsForRestaurant(widget.restaurantData['id']);
      double initialRating = double.tryParse(widget.restaurantData['rating']?.toString() ?? "0.0") ?? 0.0;

      _details = await detailsFuture;
      _address = await addressFuture;
      _reviews = await reviewsFuture;

      double averageRating = await widget.firestoreService.calculateAverageRating(widget.restaurantData['id']);

      if (_reviews.isNotEmpty) {
        _finalRating = (initialRating * 0.5 + averageRating * 0.5);
      } else {
        _finalRating = initialRating;
      }
    } catch (e) {
      print("Fehler beim Laden der Marker-Panel-Daten: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToUserProfileHelper(String userId) {
    Navigator.pop(context);
    Future.delayed(Duration(milliseconds: 50), () {
      widget.markerManager._navigateToUserProfile(userId, navigatorKey.currentContext!);
    });
  }

  void _showRatingDialogHelper() {
    Navigator.pop(context);
    Future.delayed(Duration(milliseconds: 100), () {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (BuildContext dialogContext) {
          return RatingDialog(
            restaurantId: widget.restaurantData['id'],
            onRatingSubmitted: (rating, comment) async {
              final String userId = FirebaseAuth.instance.currentUser!.uid;
              await widget.markerManager._loadUserData(userId);
              final String userName = widget.markerManager.userData?['name'] ?? "Unbekannter Nutzer";
              final String userProfileUrl = widget.markerManager.userData?['photoUrl'] ?? "";
              try {
                 await widget.firestoreService.addReview(widget.restaurantData['id'], rating, comment, userId, userName, userProfileUrl);
                 ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                    SnackBar(content: Text("Bewertung erfolgreich gespeichert!"), backgroundColor: Colors.green,)
                 );
              } catch (e) {
                  ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                    SnackBar(content: Text("Fehler: ${e.toString()}"), backgroundColor: Colors.red)
                  );
              }
            },
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollContainer) {
        if(_isLoading) {
          return Center(child: CircularProgressIndicator());
        } else {
          // ignore: sized_box_for_whitespace
          return Container(
            width: double.infinity,
            child: SingleChildScrollView(
              controller: scrollContainer,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.restaurantData['name'] ?? "Unbekannt",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8,),
                    Text(
                      _address ?? "Adresse nicht verfügbar",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16,),
                    if (_details?['priceLevel'] != null) ...[
                      Text("💰 Preisniveau", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(_details?['priceLevel'] ?? "", style: TextStyle(fontSize: 16)),
                      SizedBox(height: 8,),
                    ],
                    if (_details?['description'] != null) ...[
                      Text("📌 Beschreibung", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(_details?['description'] ?? "", style: TextStyle(fontSize: 16)),
                      SizedBox(height: 16,),
                    ],
                    if (_details?['openingHours'] != null) ...[
                      Text("🕒 Öffnungszeiten", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: _formatOpeningHours(_details?['openingHours'])),
                      SizedBox(height: 16,),
                    ],
                    if (_details?['cuisines'] is List && (_details?['cuisines'] as List).isNotEmpty) ...[
                      Text("🍽️ Küche", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: _formatLists(_details?["cuisines"])),
                      SizedBox(height: 8,),
                    ],
                    if (_details?['dietaryRestrictions'] is List && (_details?['dietaryRestrictions'] as List).isNotEmpty) ...[
                      Text("🥦 Ernährungsweisen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: _formatLists(_details?["dietaryRestrictions"])),
                      SizedBox(height: 8,),
                    ],
                    if (_details?['mealTypes'] is List && (_details?['mealTypes'] as List).isNotEmpty) ...[
                      Text("🍽️ Mahlzeiten", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: _formatLists(_details?["mealTypes"])),
                      SizedBox(height: 8,),
                    ],
                    if (widget.restaurantData['rating'] != null) ...[
                      Text(
                        "⭐ Bewertung",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text("${_finalRating.toStringAsFixed(1)} / 5.0", style: TextStyle(fontSize: 16)),
                      ElevatedButton(
                        onPressed: _showRatingDialogHelper,
                        child: Text("Bewerten"),
                      ),
                      SizedBox(height: 16),

                      if(_reviews.isNotEmpty) ...[
                        Text(
                            "Bewertungen:",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _reviews.map((review) {
                              Timestamp? timestamp = review['timestamp'];
                              String timeAgoString = "";
                              if (timestamp != null) {
                                try {
                                    timeAgoString = timeago.format(timestamp.toDate(), locale: 'de_short');
                                } catch(e) {
                                    print("Error formatting timeago in marker panel: $e");
                                    timeAgoString = DateFormat('dd.MM.yy').format(timestamp.toDate());
                                }
                              }

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: review['userProfileUrl'] != null && review['userProfileUrl'].isNotEmpty
                                    ? NetworkImage(review['userProfileUrl'])
                                    : null,
                                  child: (review['userProfileUrl'] == null || review['userProfileUrl'].isEmpty)
                                    ? Icon(Icons.person)
                                    : null,
                                ),
                                title: Text(review['userName'] ?? 'Unbekannt'),
                                subtitle: Text("${review['rating']} ⭐: ${review['comment']}"),
                                onTap: () => _navigateToUserProfileHelper(review['userId']),
                              );
                            }).toList(),
                          ),
                        ] else if (!_isLoading) ...[
                          Text("Noch keine Bewertungen vorhanden.", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        ]
                    ],
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  static List<Widget> _formatOpeningHours(dynamic openingHours) {
    if (openingHours is! List<dynamic>) {
      print("⚠️ Fehler: openingHours hat den falschen Typ (${openingHours.runtimeType}). Setze auf leer.");
      return [Text("Keine Öffnungszeiten verfügbar", style: TextStyle(fontSize: 16))];
    }

    List<String> hoursList = openingHours.map((e) => e.toString()).toList();
    return hoursList.map((entry) => Text(entry, style: TextStyle(fontSize: 16))).toList();
  }

  static List<Widget> _formatLists(dynamic list) {
    if(list is! List<dynamic>) {
      return [Text("Keine Informationen verfügbar", style: TextStyle(fontSize: 16))];
    }

    List<String> stringList = list.map((e) => e.toString()).toList();
    return stringList.map((entry) => Text(entry, style: TextStyle(fontSize: 16))).toList();
  }*/
}