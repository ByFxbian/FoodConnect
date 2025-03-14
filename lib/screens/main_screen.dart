import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:foodconnect/screens/home_screen.dart';
import 'package:foodconnect/screens/search_screen.dart';
import 'package:foodconnect/screens/profile_screen.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

class MainScreen extends StatefulWidget {
  final int initialPage;
  final LatLng? targetLocation;
  final String? selectedRestaurantId;

  MainScreen({
    this.initialPage = 0,
    this.targetLocation,
    this.selectedRestaurantId
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  LatLng? targetLocation;
  String? selectedRestaurantId;
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialPage;
    targetLocation = widget.targetLocation;
    selectedRestaurantId = widget.selectedRestaurantId;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if(index != 0) {
        targetLocation = null;
        selectedRestaurantId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      HomeScreen(
        targetLocation: targetLocation,
        selectedRestaurantId: selectedRestaurantId,
      ),
      SearchScreen(),
      ProfileScreen()
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: pages[_selectedIndex],
      ),
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          clipBehavior: Clip.antiAlias,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 70,
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
                type: BottomNavigationBarType.fixed,
                enableFeedback: true,
                items: [
                  BottomNavigationBarItem(
                    icon: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      //onTap: () => _onItemTapped(0),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Icon(Platform.isIOS ? CupertinoIcons.map : Icons.map, size: 25),
                      ),
                    ),
                    /*Padding(
                      padding: EdgeInsets.only(top: 8), // Icons zentrieren
                      child: Icon(Platform.isIOS ? CupertinoIcons.map : Icons.map, size: 25),
                    ),*/ 
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      //onTap: () => _onItemTapped(1),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Icon(Platform.isIOS ? CupertinoIcons.search : Icons.search, size: 25),
                      ),
                    ),
                    label: 'Suche',
                  ),
                  BottomNavigationBarItem(
                    icon: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      //onTap: () => _onItemTapped(2),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Icon(Platform.isIOS ? CupertinoIcons.person : Icons.person, size: 25),
                      ),
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