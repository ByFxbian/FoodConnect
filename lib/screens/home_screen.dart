// ignore_for_file: use_build_context_synchronously, unnecessary_breaks

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:foodconnect/services/database_service.dart';
import 'package:foodconnect/utils/app_theme.dart';
import 'package:foodconnect/utils/marker_manager.dart';
import 'package:foodconnect/utils/match_calculator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  final LatLng? targetLocation;
  final String? selectedRestaurantId;

  const HomeScreen({Key? key, this.targetLocation, this.selectedRestaurantId}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
  // AIzaSyA6KNBT7_34B_1ibmPvArMOVfvjrbXTx6E IOS
  // AIzaSyAdoiyJg_cGgmKrrsLJeBxsqcWXf0knLqA Android
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final DatabaseService _dbService = DatabaseService();

  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _allRestaurants = [];
  List<Map<String, dynamic>> _visibleRestaurants = [];
  Map<String, dynamic> _userProfile = {};
  
  bool _isLoading = true;
  String? _mapStyleString;
  late PageController _pageController;

  String _selectedCategory = "Alle";
  final List<String> _categories = ["Alle", "Top Match", "Geöffnet", "Günstig", "Italienisch", "Asiatisch"];

  static const CameraPosition _initialPositin = CameraPosition(
    target: LatLng(48.2082, 16.3738),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _loadMapStyle();
    _initData();
  }

  Future<void> _loadMapStyle() async {
    try {
      String style = await rootBundle.loadString('assets/map_styles/map_style_dark.json');
      setState(() {
        _mapStyleString = style;
      });
    } catch (e) {
      print("Fehler beim Laden des Map Styles: $e");
    }
  }

  Future<void> _initData() async {
    final user = FirebaseAuth.instance.currentUser;
    if(user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if(mounted && doc.exists) {
        _userProfile = doc.data()?['tasteProfile'] ?? {};
      } 
    }

    final restaurants = await _dbService.getAllRestaurants();

    if(!mounted) return;

    setState(() {
      _allRestaurants = restaurants;
      _visibleRestaurants = restaurants;
      _generateMarkers();
      _isLoading = false;
    });
  }

  void _filterRestaurants(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == "Alle") {
        _visibleRestaurants = _allRestaurants;
      } else if (category == "Top Match") {
        // Filter nach Score > 80
        _visibleRestaurants = _allRestaurants.where((r) {
          return MatchCalculator.calculate(_userProfile, r) >= 80;
        }).toList();
      } else if (category == "Günstig") {
        _visibleRestaurants = _allRestaurants.where((r) => 
          (r['priceLevel'] ?? "").toString().contains("€") && 
          !(r['priceLevel'] ?? "").toString().contains("€€€")
        ).toList();
      } else {
        // Suche in Cuisine Strings
        _visibleRestaurants = _allRestaurants.where((r) => 
          (r['cuisines'] ?? "").toString().contains(category)
        ).toList();
      }
      
      _generateMarkers();
      
      // Wenn Filter leer, zeige Feedback (optional)
      if (_visibleRestaurants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Keine Restaurants für '$category' gefunden."), duration: Duration(seconds: 1))
        );
      } else {
        // Reset PageView
        if (_pageController.hasClients) _pageController.jumpToPage(0);
      }
    });
  }
  
  void _generateMarkers() {
    _markers = _visibleRestaurants.map((rest) {
      return Marker(
        markerId: MarkerId(rest['id']),
        position: LatLng(rest['latitude'] ?? 48.0, rest['longitude'] ?? 16.0),
        // Wir nutzen hier Standard-Marker eingefärbt, bis MarkerManager 100% steht
        icon: MarkerManager().customIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        onTap: () {
          final index = _visibleRestaurants.indexOf(rest);
          if (index != -1 && _pageController.hasClients) {
            _pageController.animateToPage(
              index, 
              duration: 500.ms, 
              curve: Curves.easeOutExpo
            );
          }
        },
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // 1. Google Map
          // Wenn Style noch nicht geladen ist, zeigen wir kurz Schwarz, um den "Flash" zu vermeiden
          GoogleMap(
                initialCameraPosition: _initialPositin,
                markers: _markers,
                // HIER IST DER FIX: Style direkt im Widget setzen!
                style: _mapStyleString, 
                zoomControlsEnabled: false,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  if (!_controller.isCompleted) {
                    _controller.complete(controller);
                    if (widget.targetLocation != null) {
                      controller.animateCamera(CameraUpdate.newLatLngZoom(widget.targetLocation!, 16));
                    }
                  }
                },
              ),

          // 2. Kategorien (Oben)
          SafeArea(
            child: Container(
              height: 45,
              margin: EdgeInsets.only(top: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => _filterRestaurants(cat),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : AppTheme.surface.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : AppTheme.surfaceHighlight,
                            width: 1
                          ),
                          boxShadow: [
                            if(!isSelected) BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0,4))
                          ]
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ).animate().fadeIn().slideY(begin: -0.5, end: 0),
          ),

          // 3. Restaurant Feed (Unten)
          if (!_isLoading && _visibleRestaurants.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              height: 160,
              child: PageView.builder(
                controller: _pageController,
                physics: BouncingScrollPhysics(),
                itemCount: _visibleRestaurants.length,
                onPageChanged: (index) {
                  final rest = _visibleRestaurants[index];
                  _controller.future.then((c) => c.animateCamera(CameraUpdate.newLatLng(LatLng(rest['latitude'], rest['longitude']))));
                },
                itemBuilder: (context, index) {
                  return _buildCard(_visibleRestaurants[index]);
                },
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> rest) {
    final matchScore = MatchCalculator.calculate(_userProfile, rest);
    final imageUrl = rest['photoUrl'] != null && rest['photoUrl'].isNotEmpty 
        ? rest['photoUrl'] 
        : "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=1000&auto=format&fit=crop";

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      decoration: BoxDecoration(
        color: AppTheme.surface, // Solid Zinc
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceHighlight), // Subtiler Rand
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Bild
          SizedBox(
            width: 130,
            height: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_,__) => Container(color: AppTheme.surfaceHighlight),
                  errorWidget: (_,__,___) => Container(color: AppTheme.surfaceHighlight, child: Icon(Icons.restaurant)),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: matchScore > 80 ? Colors.green : AppTheme.primary)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("$matchScore%", style: TextStyle(color: matchScore > 80 ? Colors.green : AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                        SizedBox(width: 4),
                        Text("Match", style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rest['name'] ?? "Restaurant", style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 4),
                      Text("${rest['cuisines'] ?? 'Essen'} • ${rest['priceLevel'] ?? '€€'}", style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: AppTheme.primary, size: 18),
                      SizedBox(width: 4),
                      Text("${rest['rating'] ?? 0.0}", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

/*class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? mapController;
  static Set<Marker> markers = {};
  final DatabaseService databaseService = DatabaseService();
  final Completer<GoogleMapController> _controller = Completer();
  String? _mapStyleString;
  static bool isFirstLoad = true;
  bool _mapVisible = true;
  final GlobalKey<PopupMenuButtonState<String>> filterButtonKey = GlobalKey<PopupMenuButtonState<String>>();
  final GlobalKey filterButtonKeyNew = GlobalKey();

  String selectedSortBy = "highestRated";
  bool filterOpenNow = false;
  double filterMinRating = 0.0;
  String? filterPriceLevel;
  List<String> filterCuisines = [];

  String selectedFilter = "highestRated";
  Position position = Position(
      longitude: 16.363449,
      latitude: 48.210033,
      timestamp: DateTime(2024),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0);


  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _moveToCurrentLocation();

    if (isFirstLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        //_loadMarkers();
        _updateFilteredMarkers();
      });
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text("Sortieren & Filtern", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                SizedBox(height: 16),
                Text("Sortieren nach", style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile<String>(
                  title: Text("Beste Bewertung"),
                  value: "highestRated",
                  groupValue: selectedSortBy,
                  onChanged: (val) => setModalState(() => selectedSortBy = val!),
                ),
                RadioListTile<String>(
                  title: Text("Kürzeste Entfernung"),
                  value: "nearest",
                  groupValue: selectedSortBy,
                  onChanged: (val) => setModalState(() => selectedSortBy = val!),
                ),

                Divider(),

                SizedBox(height: 16),
                Text("Filtern nach", style: TextStyle(fontWeight: FontWeight.bold)),
                SwitchListTile.adaptive(
                  title: Text("Nur geöffnete Restaurants"),
                  value: filterOpenNow,
                  onChanged: (val) => setModalState(() => filterOpenNow = val),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Text("Mindestbewertung: ${filterMinRating.toStringAsFixed(1)} ★"),
                ),
                Slider(
                  value: filterMinRating,
                  min: 0.0,
                  max: 5.0,
                  divisions: 50,
                  label: filterMinRating.toStringAsFixed(1),
                  onChanged: (val) => setModalState(() => filterMinRating = val),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 5,
                  children: ["Italienisch", "Asiatisch", "Mexikanisch", "Amerikanisch", "Vegetarisch"]
                    .map((cuisine) => FilterChip(
                      label: Text(cuisine),
                      selected: filterCuisines.contains(cuisine),
                      onSelected: (bool selected) {
                        setModalState(() {
                          if(selected) {
                            filterCuisines.add(cuisine);
                          } else {
                            filterCuisines.remove(cuisine);
                          }
                        });
                      },
                    )).toList(),
                ),

                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateFilteredMarkers();
                  },
                  child: Text("Anwenden"),
                )
              ],
            ),
          );
        });
      }
    );
  }

  void _showMaterialFilterMenu(BuildContext context) {
    final RenderBox? buttonRenderBox = filterButtonKeyNew.currentContext?.findRenderObject() as RenderBox?;
    if (buttonRenderBox == null) return;

    final position = buttonRenderBox.localToGlobal(Offset.zero);
    final size = buttonRenderBox.size;

    final menuPosition = RelativeRect.fromLTRB(
      position.dx - size.width * 2,
      position.dy + size.height + 5,
      position.dx,
      position.dy + size.height + 100, 
    );

    showMenu<String>(
      context: context,
      position: menuPosition,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: "highestRated",
          child: Row(
            children: [
              if (selectedFilter == "highestRated") Icon(Icons.check, color: Colors.green), // Material Icon
              SizedBox(width: 8),
              Text("Beste Bewertung"),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: "nearest",
          child: Row(
            children: [
              if (selectedFilter == "nearest") Icon(Icons.check, color: Colors.green), // Material Icon
              SizedBox(width: 8),
              Text("Kürzeste Entfernung"),
            ],
          ),
        ),
      ],
    ).then((String? newValue) {
      if (newValue != null) {
        setState(() {
          selectedFilter = newValue;
        });
        _updateFilteredMarkers();
      }
    }) ;
  } 

  void _showCupertinoFilterMenu(BuildContext context) {
    showCupertinoModalPopup<String>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('Filter wählen'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context, 'highestRated'); 
            },
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selectedFilter == "highestRated") Icon(CupertinoIcons.check_mark, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Beste Bewertung'),
                ],
              ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context, 'nearest');
            },
             child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selectedFilter == "nearest") Icon(CupertinoIcons.check_mark, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Kürzeste Entfernung'),
                ],
              ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Abbrechen'),
        ),
      ),
    ).then((String? newValue) {
       
       if (newValue != null) {
         setState(() {
           selectedFilter = newValue;
         });
         _updateFilteredMarkers();
       }
    });
  }

  Future<void> _loadMapStyle() async {
    try {
      _mapStyleString = await DefaultAssetBundle.of(context).loadString('assets/map_styles/map_style_final.json');
      if(!mounted) return;
      setState(() {});
    } catch (e) {
      print("Fehler beim Laden des Map-Stils: $e");
    }
  }

  Future<void> _loadMarkers({bool forceRefresh = false}) async {
    print("Lade Marker aus MarkerManager...");

    if (!mounted || (!isFirstLoad && !forceRefresh)) return;

    Set<Marker> newMarkers = MarkerManager().markers;

    if (!mounted) return;

    setState(() {
      markers = newMarkers;
      isFirstLoad = false;
    });
  }

  Future<void> _moveToSelectedLocation() async {
    print("📌 _moveToSelectedLocation() aufgerufen!");
    if (!mounted) return;
    if (widget.targetLocation == null) {
        print("⚠️ Keine Ziel-Location vorhanden.");
        return;
    }

    Future.delayed(Duration(milliseconds: 500), () {
        if (!mounted) {
            return;
        }

        mapController?.animateCamera(CameraUpdate.newLatLngZoom(
            widget.targetLocation!,
            14.0,
        ));

        print("✅ Marker gefunden! Öffne Panel...");
        _showMarkerPanelForRestaurant(widget.selectedRestaurantId);
    });
  }

  void _showMarkerPanelForRestaurant(String? restaurantId) async {
    if(restaurantId == null) return;

    Map<String, dynamic>? restaurantData = await databaseService.getRestaurantById(restaurantId);

    if (restaurantData == null) return;

    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    MarkerManager().showMarkerPanel(ctx, restaurantData);
  }

  Future<void> _moveToCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    if (!mounted) return;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    LocationSettings locationSettings = LocationSettings(
      accuracy: LA.LocationAccuracy.high,
      distanceFilter: 10,
    );

    try {
      Position newPosition = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
      if (!mounted) return;
      setState(() {
        position = newPosition;
        _mapVisible = false;
      });

      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {
          _mapVisible = true;
        });

        mapController?.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14.0,
        ));
      });
    } catch (e) {
      print("Fehler beim Abrufen des Standorts: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Standort konnte nicht abgerufen werden.')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    LocationSettings locationSettings = LocationSettings(
      accuracy: LA.LocationAccuracy.high,
      distanceFilter: 10,
    );

    position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
  }

  Future<void> _updateFilteredMarkers() async {
    if (!mounted || mapController == null) return;

    LatLngBounds? visibleRegion = await mapController?.getVisibleRegion();
    if (visibleRegion == null) return;

    if (selectedSortBy == "nearest") {
      await _getCurrentLocation();
    }

    List<Map<String, dynamic>> filteredMarkersData = await databaseService.getFilteredRestaurants(
      minLat: visibleRegion.southwest.latitude,
      minLng: visibleRegion.southwest.longitude,
      maxLat: visibleRegion.northeast.latitude,
      maxLng: visibleRegion.northeast.longitude,
      userLat: position.latitude,
      userLng: position.longitude,
      sortBy: selectedSortBy == "nearest" ? "distance" : "rating",
      openNow: filterOpenNow,
      minRating: filterMinRating,
      priceLevel: filterPriceLevel,
      cuisines: filterCuisines,
      limit: 100,
    );

    Set<Marker> updatedMarkers = filteredMarkersData.map((data) {
      return Marker(
        markerId: MarkerId(data['id']),
        position: LatLng(data['latitude'], data['longitude']),
        icon: MarkerManager().customIcon!,
        onTap: () {
          final ctx = navigatorKey.currentContext;
          if (ctx == null) return;
          MarkerManager().showMarkerPanel(ctx, data);
        },
      );
    }).toSet();

    if(mounted) {
      setState(() {
        markers = updatedMarkers;
        MarkerManager().markers = updatedMarkers;
        markers = MarkerManager().markers;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(48.210033, 16.363449),
              zoom: 12,
            ),
            markers: markers,
            myLocationEnabled: true,
            mapType: MapType.normal,
            tiltGesturesEnabled: false,
            rotateGesturesEnabled: false,
            minMaxZoomPreference: MinMaxZoomPreference(11, 20),
            onCameraIdle: () {
              _updateFilteredMarkers();
            },
            onMapCreated: (controller) {
              if (!mounted) return;
              setState(() {
                mapController = controller;
              });
              _controller.complete(controller);
              if(isFirstLoad) {
                isFirstLoad = false;
                _moveToCurrentLocation();
              }
              if(widget.targetLocation != null) {
                _moveToSelectedLocation();
              }
            },
          ),
         floatingActionButton: Align(
          alignment: Alignment.topRight,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 15.0, right: 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    key: filterButtonKeyNew,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: Offset(2,2),
                        )
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          _showFilterModal();
                        },
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Platform.isIOS ? CupertinoIcons.list_dash : Icons.filter_list,
                            color: Colors.white,
                            size: 30
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15.0),
                  FloatingActionButton(
                    heroTag: "location_button",
                    onPressed: _moveToCurrentLocation,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(Platform.isIOS ? CupertinoIcons.location : Icons.my_location, color: Theme.of(context).colorScheme.onPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }

  Future<void> _updateInvisibleMarkers() async {
    if (!mounted) return;
    if(mapController == null) return;

    LatLngBounds? visibleRegion = await mapController?.getVisibleRegion();
    if(visibleRegion == null) return;

    List<Map<String, dynamic>> filteredMarkers = 
      await databaseService.getHighestRatedInBounds(
        visibleRegion.southwest.latitude,
        visibleRegion.southwest.longitude,
        visibleRegion.northeast.latitude,
        visibleRegion.northeast.longitude,
        100
      );

      Set<Marker> updatedMarkers = {};
      for (var data in filteredMarkers.take(100)) {
        Marker marker = Marker(
          markerId: MarkerId(data['id']),
          position: LatLng(data['latitude'], data['longitude']),
          icon: MarkerManager().customIcon!,
          onTap: () {
            final ctx = navigatorKey.currentContext;
            if (ctx == null) return;
            MarkerManager().showMarkerPanel(ctx, data);
          },
        );
        updatedMarkers.add(marker);
      }

      setState(() {
        markers = updatedMarkers;
        MarkerManager().markers = updatedMarkers;
        markers = MarkerManager().markers;
      });
  }

}*/