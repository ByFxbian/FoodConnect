// ignore_for_file: use_build_context_synchronously, unnecessary_breaks

import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/main.dart';
import 'package:foodconnect/services/database_service.dart';
import 'package:foodconnect/utils/marker_manager.dart';
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
  static bool isFirstLoad = true;

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

  Future<void> _loadMapStyle() async {
    try {
      _mapStyleString = await DefaultAssetBundle.of(context).loadString('assets/map_styles/map_style.json');
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
    if (!mounted) return;

    LatLngBounds? visibleRegion = await mapController?.getVisibleRegion();
    if (visibleRegion == null) return;

    List<Map<String, dynamic>> filteredMarkers;

    await _getCurrentLocation();

    if (selectedFilter == "highestRated") {
      filteredMarkers = await databaseService.getHighestRatedInBounds(
        visibleRegion.southwest.latitude,
        visibleRegion.southwest.longitude,
        visibleRegion.northeast.latitude,
        visibleRegion.northeast.longitude,
        100,
      );
    } else if (selectedFilter == "nearest") {
      filteredMarkers = await databaseService.getNearestRestaurantsInBounds(
        position.latitude,
        position.longitude,
        visibleRegion.southwest.latitude,
        visibleRegion.southwest.longitude,
        visibleRegion.northeast.latitude,
        visibleRegion.northeast.longitude,
        100,
      );
    } else if (selectedFilter == "openNow") {
      filteredMarkers = await databaseService.getOpenRestaurantsInBounds(
        visibleRegion.southwest.latitude,
        visibleRegion.southwest.longitude,
        visibleRegion.northeast.latitude,
        visibleRegion.northeast.longitude,
        100,
      );
    } else {
      filteredMarkers = await databaseService.getRestaurantsInBounds(
        visibleRegion.southwest.latitude,
        visibleRegion.southwest.longitude,
        visibleRegion.northeast.latitude,
        visibleRegion.northeast.longitude,
      );
    }

    Set<Marker> updatedMarkers = filteredMarkers.map((data) {
      return Marker(
        markerId: MarkerId(data['id']),
        position: LatLng(data['latitude'], data['longitude']),
        icon: MarkerManager().customIcon,
        onTap: () {
          final ctx = navigatorKey.currentContext;
          if (ctx == null) return;
          MarkerManager().showMarkerPanel(ctx, data);
        },
      );
    }).toSet();

    setState(() {
      markers = updatedMarkers;
      MarkerManager().markers = updatedMarkers;
    });
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
      body: PlatformMap(
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
              _updateInvisibleMarkers();
            },
            googleMapsStyle: _mapStyleString,
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
          floatingActionButton: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(top: 50, right: 10),
                  child: PopupMenuButton<String>(
                    icon: Icon(Platform.isIOS ? CupertinoIcons.list_dash : Icons.filter_list, color: Theme.of(context).colorScheme.surface, size: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                    ),
                    color: Theme.of(context).colorScheme.surface,
                    onSelected: (value) {
                      setState(() {
                        selectedFilter = value;
                      });
                      _updateFilteredMarkers();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: "highestRated",
                        child: Row(
                          children: [
                            if (selectedFilter == "highestRated") Icon(Platform.isIOS ? CupertinoIcons.check_mark : Icons.check, color: Colors.green),
                            SizedBox(width: 8),
                            Text("Beste Bewertung"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "nearest",
                        child: Row(
                          children: [
                            if (selectedFilter == "nearest") Icon(Platform.isIOS ? CupertinoIcons.check_mark : Icons.check, color: Colors.green),
                            SizedBox(width: 8),
                            Text("Kürzeste Entfernung"),
                          ],
                        ),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: "openNow",
                        child: Row(
                          children: [
                            if (selectedFilter == "openNow") Icon(Platform.isIOS ? CupertinoIcons.check_mark : Icons.check, color: Colors.green),
                            SizedBox(width: 8),
                            Text("Jetzt geöffnet"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(bottom: 90, right: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /*FloatingActionButton.small(
                      heroTag: "reload_button",
                      onPressed: () => _loadMarkers(forceRefresh: true),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: Icon(Platform.isIOS ? CupertinoIcons.refresh : Icons.refresh, color: Theme.of(context).colorScheme.onPrimary),
                    ),*/
                    SizedBox(height: 10),
                    FloatingActionButton(
                      heroTag: "location_button",
                      onPressed: _moveToCurrentLocation,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(Platform.isIOS ? CupertinoIcons.location : Icons.my_location, color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ],
                )
              ),
            ),
            ],
          ) 
    );
  }

  Future<void> _updateInvisibleMarkers() async {
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
          icon: MarkerManager().customIcon,
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

}