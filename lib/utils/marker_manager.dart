// ignore_for_file: unused_local_variable

import 'dart:ui' as ui;
// Import hinzugefügt
import 'package:flutter/services.dart';

// Import hinzugefügt
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerManager {
  static final MarkerManager _instance = MarkerManager._internal();
  factory MarkerManager() => _instance;
  MarkerManager._internal();

  BitmapDescriptor? customIcon;
  BitmapDescriptor? highlightedIcon;

  Future<void> loadCustomIcons() async {
    if (customIcon != null) return;

    try {
      customIcon =
          await _bitmapDescriptorFromAssetBytes('assets/icons/mapicon.png', 50);

      highlightedIcon =
          await _bitmapDescriptorFromAssetBytes('assets/icons/mapicon.png', 70);
    } catch (e) {
      print("Fehler beim Laden der Icons: $e");
    }
  }

  Future<BitmapDescriptor> _bitmapDescriptorFromAssetBytes(
      String path, int width) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui
        .instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData =
        await fi.image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception("Bild konnte nicht konvertiert werden.");
    }

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
      if (context.mounted) {
        context.go('/profile');
      }
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

      _details = await detailsFuture;
      _address = await addressFuture;
      _finalRating = double.tryParse(widget.restaurantData['rating']?.toString() ?? '0.0') ?? 0.0;
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



  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollContainer) {
        if (_isLoading) {
          return Center(child: CircularProgressIndicator.adaptive());
        } else {
          final imageUrl = widget.restaurantData['photoUrl'] as String?;
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5), width: 1.0)),
            ),
            child: SingleChildScrollView(
              controller: scrollContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Image Area
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Icon(Icons.restaurant, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Save Action Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.restaurantData['name'] ?? "Unbekannt",
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            IconButton(
                              onPressed: () {
                                if (widget.restaurantData['id'] != null) {
                                  SaveToListSheet.show(context, widget.restaurantData['id']);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ID nicht gefunden")));
                                }
                              },
                              icon: Icon(CupertinoIcons.bookmark),
                              color: Theme.of(context).primaryColor,
                              iconSize: 28,
                            ),
                          ],
                        ),
                        SizedBox(height: 8),

                        // Subinfo Row (Rating, Distance, etc.)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.star_rounded, size: 20, color: Theme.of(context).primaryColor),
                            SizedBox(width: 4),
                            Text(
                              "${_finalRating.toStringAsFixed(1)}",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (_details?['priceLevel'] != null) ...[
                              SizedBox(width: 12),
                              Text("•", style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                              SizedBox(width: 12),
                              Text(_details!['priceLevel'], style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ]
                        ),
                        SizedBox(height: 16),

                        Text(
                          _address ?? "Adresse nicht verfügbar",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                        SizedBox(height: 24),

                        if (_details?['description'] != null) ...[
                          Text("Beschreibung", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text(_details!['description'], style: Theme.of(context).textTheme.bodyMedium),
                          SizedBox(height: 24),
                        ],


                      ],
                    ),
                  ),
                ],
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
