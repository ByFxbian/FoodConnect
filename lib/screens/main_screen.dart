import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:foodconnect/screens/home_screen.dart';
import 'package:foodconnect/screens/search_screen.dart';
import 'package:foodconnect/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  MainScreen({required this.onThemeChanged});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(),
      SearchScreen(),
      ProfileScreen(onThemeChanged: widget.onThemeChanged)
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
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                selectedItemColor: Colors.deepPurple,
                unselectedItemColor: Colors.black.withOpacity(0.7),
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