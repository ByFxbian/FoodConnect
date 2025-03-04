// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:foodconnect/screens/loading_screen.dart';
import 'package:foodconnect/services/database_service.dart';
import 'package:foodconnect/widgets/marker_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';
// ignore: depend_on_referenced_packages, implementation_imports
import 'package:geolocator_platform_interface/src/enums/location_accuracy.dart' as LA;

class HomeScreen extends StatefulWidget {
  final LatLng? targetLocation;
  final String? selectedRestaurantId;

  HomeScreen({this.targetLocation, this.selectedRestaurantId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
  // AIzaSyA6KNBT7_34B_1ibmPvArMOVfvjrbXTx6E IOS
  // AIzaSyAdoiyJg_cGgmKrrsLJeBxsqcWXf0knLqA Android
}

class _HomeScreenState extends State<HomeScreen> {
  PlatformMapController? mapController;
  static Set<Marker> markers = {};
  final DatabaseService databaseService = DatabaseService();
  final Completer<PlatformMapController> _controller = Completer();
  String? _mapStyleString;
  bool isLoading = false;
  static bool isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _moveToCurrentLocation();

    if (isFirstLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMarkers();
      });
    }
  }

  Future<void> _loadMapStyle() async {
    try {
      _mapStyleString = await DefaultAssetBundle.of(context).loadString('assets/map_styles/map_style.json');
      setState(() {});
    } catch (e) {
      print("Fehler beim Laden des Map-Stils: $e");
    }
  }

  Future<void> _loadMarkers({bool forceRefresh = false}) async {
    if (!mounted || (!isFirstLoad && !forceRefresh)) return;

    setState(() {
      isLoading = true;
    });

    List<Map<String, dynamic>> markerData = await databaseService.getAllRestaurants();
    Set<Marker> newMarkers = {};

    for (var data in markerData) {
      if (!mounted) return;

      String iconPath = data['icon'] ?? '';
      bool isUrl = iconPath.startsWith('http') || iconPath.startsWith('https');
      String finalIconPath = isUrl ? iconPath : "assets/icons/mapicon.png";

      MarkerWidget marker = MarkerWidget(
        id: data['id'] ?? 'unknown',
        name: data['name'] ?? 'Unbekannt',
        position: LatLng(data['latitude'], data['longitude']),
        iconPath: finalIconPath,
        description: data['description'] ?? 'Keine Beschreibung verfügbar',
        openingHours: data['openingHours'] ?? '00:00 - 00:00',
        rating: data['rating'].toString(),
        parentContext: context,
      );

      newMarkers.add(await marker.toMarker(context));
    }

    if (!mounted) return;

    setState(() {
      markers = newMarkers;
      isLoading = false;
      isFirstLoad = false;
    });
  }

  // ignore: unused_element
  Future<void> _moveToSelectedLocation() async {
    print("📌 _moveToSelectedLocation() aufgerufen!");
    if (widget.targetLocation == null) {
        print("⚠️ Keine Ziel-Location vorhanden.");
        return;
    }

    Future.delayed(Duration(milliseconds: 500), () {
        if (!mounted) {
            print("❌ Widget ist nicht mehr gemounted.");
            return;
        }

        print("✅ Marker gefunden! Öffne Panel...");
        _showMarkerPanelForRestaurant(widget.selectedRestaurantId);
    });
  }

  void _showMarkerPanelForRestaurant(String? restaurantId) async {
    print(restaurantId);
    if(restaurantId == null) return;

    Map<String, dynamic>? restaurantData = await databaseService.getRestaurantById(restaurantId);

    if (restaurantData == null) return;

    MarkerWidget selectedMarker = MarkerWidget(
      id: restaurantId,
      name: restaurantData['name'] ?? "Unbekannt",
      position: LatLng(restaurantData['latitude'], restaurantData['longitude']),
      iconPath: "assets/icons/${restaurantData['icon'] ?? 'mapicon.png'}",
      description: restaurantData['description'] ?? "Keine Beschreibung verfügbar",
      openingHours: restaurantData['openingHours'] ?? '00:00 - 00:00',
      rating: restaurantData['rating'].toString(),
      parentContext: context
    );

    selectedMarker.showMarkerPanel(context);
  }

  Future<void> _moveToCurrentLocation() async {
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

    Position position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
    mapController?.animateCamera(CameraUpdate.newLatLngZoom(
      LatLng(position.latitude, position.longitude),
      14.0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*body: GoogleMap(
        style: _mapStyleString ?? "",
        initialCameraPosition: CameraPosition(
          target: LatLng(48.210033, 16.363449),
          zoom: 12,
        ),
        markers: markers,
        mapType: MapType.normal,
        onCameraIdle: _onCameraIdle,
        cameraTargetBounds: CameraTargetBounds(wienBounds),
        tiltGesturesEnabled: false,
        rotateGesturesEnabled: false,
        minMaxZoomPreference: MinMaxZoomPreference(11, 20),
        /*onCameraMove: (CameraPosition position) {
          if(position.zoom < 11) {
            mapController?.animateCamera(
              CameraUpdate.zoomTo(11)
            );
          }
        },*/
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          mapController = controller;
          if(widget.targetLocation != null) {
            _moveToSelectedLocation();
          }
          setState(() {});
        },
      ),*/
      body: isLoading
         ? LoadingScreen()
        : PlatformMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(48.210033, 16.363449),
              zoom: 12,
            ),
            markers: markers,
            mapType: MapType.normal,
            tiltGesturesEnabled: false,
            rotateGesturesEnabled: false,
            minMaxZoomPreference: MinMaxZoomPreference(11, 20),
            onMapCreated: (controller) {
              if (!mounted) return;
              setState(() {
                mapController = controller;
              });
              _controller.complete(controller);
              _moveToCurrentLocation();
            },
          ),
          floatingActionButton: isLoading 
          ? null
          : Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(bottom: 75, right: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: "reload_button",
                      onPressed: () => _loadMarkers(forceRefresh: true),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onPrimary),
                    ),
                    SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: "location_button",
                      onPressed: _moveToCurrentLocation,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(Icons.my_location, color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ],
                )
              ),
            ),
    );
  }

}