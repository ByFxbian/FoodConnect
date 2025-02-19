import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:foodconnect/widgets/marker_widget.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart' as CM;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
  // AIzaSyA6KNBT7_34B_1ibmPvArMOVfvjrbXTx6E IOS
  // AIzaSyAdoiyJg_cGgmKrrsLJeBxsqcWXf0knLqA Android
  static route() => MaterialPageRoute(
    builder: (context) => HomeScreen(),
  );
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Location location = Location();
  final FirestoreService firestoreService = FirestoreService();
  final Completer<GoogleMapController> _controller = Completer();
  String? _mapStyleString;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _loadMarkers();
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
    List<Map<String, dynamic>> markerData = await firestoreService.getMarkers();
    Set<Marker> newMarkers = {};

    for (var data in markerData) {
      GeoPoint geoPoint = data['location'] as GeoPoint;

      MarkerWidget marker = MarkerWidget(
        id: data['id'] ?? 'unknown',
        name: data['name'] ?? 'Unbekannt',
        position: LatLng(geoPoint.latitude, geoPoint.longitude),
        iconPath: "assets/icons/${data['icon'] ?? 'mapicon.png'}",
        description: data['description'] ?? 'Keine Beschreibung verfügbar',
      );

      newMarkers.add(await marker.toMarker(context));
    }

    setState(() {
      markers = newMarkers;
    });
  }

  Future<void> _moveToCurrentLocation() async {
    var userLocation = await location.getLocation();
    mapController?.animateCamera(CameraUpdate.newLatLng(
      LatLng(userLocation.latitude!, userLocation.longitude!),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        style: _mapStyleString ?? "",
        initialCameraPosition: CameraPosition(
          target: LatLng(48.210033, 16.363449),
          zoom: 12,
        ),
        markers: markers,
        mapType: MapType.normal,
        //myLocationButtonEnabled: false,
        //myLocationEnabled: true,
        //compassEnabled: false,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          mapController = controller;
          //mapController!.setMapStyle(_mapStyleString);
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

}