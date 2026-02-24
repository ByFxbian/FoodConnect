import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'dart:ui';
import 'package:go_router/go_router.dart';

//import 'package:platform_maps_flutter/platform_maps_flutter.dart';

class MainScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  void _onItemTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 65,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, CupertinoIcons.map_fill, CupertinoIcons.map),
                  _buildNavItem(
                      1, CupertinoIcons.search, CupertinoIcons.search),
                  _buildNavItem(
                      2, CupertinoIcons.person_fill, CupertinoIcons.person),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = widget.navigationShell.currentIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          size: 26,
        ),
      ),
    );
  }
}
