import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'dart:ui';
import 'package:foodconnect/screens/home_screen.dart';
import 'package:foodconnect/screens/search_screen.dart';
import 'package:foodconnect/screens/profile_screen.dart';
import 'package:foodconnect/utils/app_theme.dart';
//import 'package:platform_maps_flutter/platform_maps_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MainScreen extends StatefulWidget {
  final int initialPage;
  final LatLng? targetLocation;
  final String? selectedRestaurantId;

  MainScreen({
    super.key,
    this.initialPage = 0,
    this.targetLocation,
    this.selectedRestaurantId
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialPage;
    _screens = [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      backgroundColor: AppTheme.background,
      extendBody: true,
      bottomNavigationBar:
        SafeArea(
          child: Container(
            height: 65,
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.85),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: AppTheme.surfaceHighlight.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0, CupertinoIcons.map_fill, CupertinoIcons.map),
                      _buildNavItem(1, CupertinoIcons.search, CupertinoIcons.search),
                      _buildNavItem(2, CupertinoIcons.person_fill, CupertinoIcons.person),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          size: 26,
        ),
      ),
    );
  }
}