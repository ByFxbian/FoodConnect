import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:foodconnect/screens/home_screen.dart';
import 'package:foodconnect/screens/search_screen.dart';
import 'package:foodconnect/screens/profile_screen.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

class MainScreen extends StatefulWidget {
  //final ValueChanged<bool> onThemeChanged;
  final int initialPage;
  final LatLng? targetLocation;
  final String? selectedRestaurantId;

  MainScreen({
    /*required this.onThemeChanged,*/
    this.initialPage = 0,
    this.targetLocation,
    this.selectedRestaurantId
  });

  @override
  // ignore: library_private_types_in_public_api
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialPage;
    _pages = [
      HomeScreen(
        targetLocation: widget.targetLocation,
        selectedRestaurantId: widget.selectedRestaurantId,
      ),
      SearchScreen(),
      ProfileScreen()
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void uploadMarkers() async {
    final List<Map<String, dynamic>> markers = [
      {"name": "Onkels Kebap Restaurant", "description": "Familiärer Kebap-Laden", "id": "onkels_kebap", "location": GeoPoint(48.2105, 16.3994), "openingHours": "10:00 - 22:00", "icon": "mapicon.png", "photoUrl": "", "rating": 4.5, "type": "Restaurant"},
      {"name": "Döner'ci", "description": "Authentischer Döner mit hausgemachten Zutaten", "id": "doner_ci", "location": GeoPoint(48.1833, 16.3458), "openingHours": "10:00 - 22:00", "icon": "mapicon.png", "photoUrl": "", "rating": 4.5, "type": "Restaurant"},
      {"name": "Safran", "description": "Persischer Döner mit einzigartigem Geschmack", "id": "safran", "location": GeoPoint(48.2080, 16.3748), "openingHours": "10:00 - 22:00", "icon": "mapicon.png", "photoUrl": "", "rating": 4.5, "type": "Restaurant"},
      {"name": "Kurze Pause", "description": "Perfekt für einen schnellen Döner-Snack", "id": "kurze_pause", "location": GeoPoint(48.2102, 16.3821), "openingHours": "10:00 - 22:00", "icon": "mapicon.png", "photoUrl": "", "rating": 4.5, "type": "Restaurant"},
      {"name": "Mochi", "description": "Modernes japanisches Fusion-Restaurant", "id": "mochi", "location": GeoPoint(48.2125, 16.3869), "openingHours": "12:00 - 22:00", "icon": "mapicon.png", "photoUrl": "", "rating": 4.7, "type": "Restaurant"},
      {"name": "Tian", "description": "Vegetarische Gourmetküche", "id": "tian", "location": GeoPoint(48.2089, 16.3735), "openingHours": "12:00 - 23:00", "icon": "mapicon.png", "photoUrl": "", "rating": 4.7, "type": "Restaurant"}
    ];

    for (var marker in markers) {
      await FirebaseFirestore.instance.collection("markers").add(marker);
    }
    print("Alle Marker wurden hochgeladen!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: AppBar(
        title: Text("Upload Markers"),
        actions: [
          IconButton(
            icon: Icon(Icons.upload),
            onPressed: uploadMarkers,
          ),
        ],
      ),*/
      body: _pages[_selectedIndex],
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                showSelectedLabels: false,
                showUnselectedLabels: false,
                items: [
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(top: 5), // Icons zentrieren
                      child: Icon(Icons.map),
                    ), 
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(Icons.search),
                    ), 
                    label: 'Suche',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(Icons.person),
                    ), 
                    label: 'Profil',
                  ),
                ],
              ),
            ),
          ),
        ),
      )
    );
  }
}