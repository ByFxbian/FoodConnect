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
  bool _mapVisible = true;
  final GlobalKey<PopupMenuButtonState<String>> filterButtonKey = GlobalKey<PopupMenuButtonState<String>>();
  final GlobalKey filterButtonKeyNew = GlobalKey();

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
    if (!mounted) return;

    LatLngBounds? visibleRegion = await mapController?.getVisibleRegion();
    if (visibleRegion == null) return;

    List<Map<String, dynamic>> filteredMarkers;

    if (selectedFilter == "highestRated") {
      filteredMarkers = await databaseService.getHighestRatedInBounds(
        visibleRegion.southwest.latitude,
        visibleRegion.southwest.longitude,
        visibleRegion.northeast.latitude,
        visibleRegion.northeast.longitude,
        100,
      );
    } else if (selectedFilter == "nearest") {
      await _getCurrentLocation();
      filteredMarkers = await databaseService.getNearestRestaurantsInBounds(
        position.latitude,
        position.longitude,
        visibleRegion.southwest.latitude,
        visibleRegion.southwest.longitude,
        visibleRegion.northeast.latitude,
        visibleRegion.northeast.longitude,
        10,
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
      markers = MarkerManager().markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: AppBar(
        title: Text("DEBUG MENÜ"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          ElevatedButton(
            onPressed: () {
              NotiService().showNotification(
                title: "Title",
                body: "Body",
              );
            },
            child: Text("Send Notification Debug"),
          )
        ],
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
              _updateFilteredMarkers();
            },
            googleMapsStyle: _mapStyleString,
            googleMapsCloudMapId: '15939377b909413f',
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
          /*floatingActionButton: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: EdgeInsets.only(top: 60, right: 10),
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
                        dynamic state = filterButtonKey.currentState;
                        state.showButtonMenu();
                      },
                      child: PopupMenuButton<String>(
                        key: filterButtonKey,
                        icon: Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Platform.isIOS ? CupertinoIcons.list_dash : Icons.filter_list,
                            color: Colors.white,
                            size: 25
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                        ],
                      ),
                    ),
                  ) 
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(top: 90, right: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
          ) */
         floatingActionButton: Align(
          alignment: Alignment.topRight,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 15.0, right: 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /*Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
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
                          dynamic state = filterButtonKey.currentState;
                          state.showButtonMenu();
                        },
                        child: PopupMenuButton<String>(
                          key: filterButtonKey,
                          offset: const Offset(-120, 15),
                          icon: Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Platform.isIOS ? CupertinoIcons.list_dash : Icons.filter_list,
                              color: Colors.white,
                              size: 30
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                          ],
                        ),
                      ),
                    )
                  ),*/
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
                          if(Platform.isIOS) {
                            _showCupertinoFilterMenu(context);
                          } else {
                            _showMaterialFilterMenu(context);
                          }
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