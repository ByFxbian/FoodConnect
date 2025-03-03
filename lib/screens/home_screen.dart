// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:foodconnect/services/database_service.dart';
import 'package:foodconnect/widgets/marker_widget.dart';
import 'package:location/location.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  final LatLng? targetLocation;
  final String? selectedRestaurantId;

  HomeScreen({this.targetLocation, this.selectedRestaurantId});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
  // AIzaSyA6KNBT7_34B_1ibmPvArMOVfvjrbXTx6E IOS
  // AIzaSyAdoiyJg_cGgmKrrsLJeBxsqcWXf0knLqA Android
}

class _HomeScreenState extends State<HomeScreen> {
  PlatformMapController? mapController;
  Set<Marker> markers = {};
  Location location = Location();
  final DatabaseService databaseService = DatabaseService();
  final Completer<PlatformMapController> _controller = Completer();
  // ignore: unused_field
  String? _mapStyleString;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _loadMarkers();

    if(widget.targetLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _moveToSelectedLocation();
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

  Future<void> _loadMarkers() async {
    List<Map<String, dynamic>> markerData = await databaseService.getAllRestaurants();
    Set<Marker> newMarkers = {};

    for (var data in markerData) {
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
      );

      newMarkers.add(await marker.toMarker(context));
    }

    setState(() {
      markers = newMarkers;
    });

    if(widget.targetLocation != null) {
      _moveToSelectedLocation();
    }
  }

  Future<void> _moveToSelectedLocation() async {
    if(mapController != null && widget.targetLocation != null) {
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(widget.targetLocation!, 15),
      );

      Future.delayed(Duration(milliseconds: 500), () {
        _showMarkerPanelForRestaurant(widget.selectedRestaurantId);
      });
    }
  }

  void _showMarkerPanelForRestaurant(String? restaurantId) async {
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
    );

    selectedMarker.showMarkerPanel(context);
  }

  Future<void> _moveToCurrentLocation() async {
    var userLocation = await location.getLocation();
    mapController?.animateCamera(CameraUpdate.newLatLng(
      LatLng(userLocation.latitude!, userLocation.longitude!),
    ));
  }

  final LatLngBounds wienBounds = LatLngBounds(
    southwest: LatLng(48.1, 16.2), // Südwestlicher Punkt Wiens
    northeast: LatLng(48.35, 16.55), // Nordöstlicher Punkt Wiens
  );

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
        mapType: MapType.normal,
        onCameraIdle: _onCameraIdle,
        tiltGesturesEnabled: false,
        rotateGesturesEnabled: false,
        minMaxZoomPreference: MinMaxZoomPreference(11, 20),
        onCameraMove: (CameraPosition position) {
          if(position.zoom < 11) {
            mapController?.animateCamera(
              CameraUpdate.zoomTo(11)
            );
          }
        },
        onMapCreated: (PlatformMapController controller) {
          _controller.complete(controller);
          mapController = controller;
          if(widget.targetLocation != null) {
            _moveToSelectedLocation();
          }
          setState(() {});
        },
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.only(bottom: 75, right: 10),
          child: FloatingActionButton(
            onPressed: _moveToCurrentLocation,
            backgroundColor: Colors.deepPurple,
            child: Icon(Icons.my_location, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _onCameraIdle() async {
    if(mapController == null) return;

    LatLngBounds? visibleRegion = await mapController?.getVisibleRegion();

    if(visibleRegion != null) {
      List<Map<String, dynamic>> filteredMarkers =
          await databaseService.getRestaurantsInBounds(
        visibleRegion.southwest.latitude,
        visibleRegion.southwest.longitude,
        visibleRegion.northeast.latitude,
        visibleRegion.northeast.longitude,
      );

      Set<Marker> newMarkers = {};
      for (var data in filteredMarkers) {
        String iconPath = data['icon'] ?? '';

        bool isUrl = iconPath.startsWith('http') || iconPath.startsWith('https');
        String finalIconPath = isUrl ? iconPath : "assets/icons/mapicon.png";

        MarkerWidget marker = MarkerWidget(
          id: data['id'],
          name: data['name'],
          position: LatLng(data['latitude'], data['longitude']),
          iconPath: finalIconPath,
          description: data['description'] ?? 'Keine Beschreibung verfügbar',
          openingHours: data['openingHours'] ?? 'Nicht verfügbar',
          rating: data['rating'].toString(),
        );

        newMarkers.add(await marker.toMarker(context));
      }

      setState(() {
        markers = newMarkers;
      });
    }
  }

}