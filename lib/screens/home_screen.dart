// ignore_for_file: use_build_context_synchronously, unnecessary_breaks

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:foodconnect/services/database_service.dart';

import 'package:foodconnect/utils/marker_manager.dart';
import 'package:foodconnect/utils/match_calculator.dart';
import 'package:foodconnect/widgets/restaurant_detail_sheet.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  final LatLng? targetLocation;
  final String? selectedRestaurantId;

  const HomeScreen({super.key, this.targetLocation, this.selectedRestaurantId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
  // AIzaSyA6KNBT7_34B_1ibmPvArMOVfvjrbXTx6E IOS
  // AIzaSyAdoiyJg_cGgmKrrsLJeBxsqcWXf0knLqA Android
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final DatabaseService _dbService = DatabaseService();

  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _allRestaurants = [];
  List<Map<String, dynamic>> _visibleRestaurants = [];
  Map<String, dynamic> _userProfile = {};

  bool _isLoading = true;
  bool _showMap = false;
  String? _mapStyleString;
  late PageController _pageController;

  // Search state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _selectedCategory = "Alle";
  final List<String> _categories = [
    "Alle",
    "Top Match",
    "Geöffnet",
    "Günstig",
    "Italienisch",
    "Asiatisch"
  ];

  static const CameraPosition _initialPositin = CameraPosition(
    target: LatLng(48.2082, 16.3738),
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _loadMapStyle();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMapStyle() async {
    try {
      String style =
          await rootBundle.loadString('assets/map_styles/map_style_dark.json');
      setState(() {
        _mapStyleString = style;
      });
    } catch (e) {
      print("Fehler beim Laden des Map Styles: $e");
    }
  }

  Future<void> _initData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted && doc.exists) {
        _userProfile = doc.data()?['tasteProfile'] ?? {};
      }
    }

    final restaurants = await _dbService.getAllRestaurants();

    if (!mounted) return;

    setState(() {
      _allRestaurants = restaurants;
      _visibleRestaurants = restaurants;
      _generateMarkers();
      _isLoading = false;
    });
  }

  void _filterRestaurants(String category) {
    setState(() {
      _selectedCategory = category;
      // clear search when switching categories
      if (_isSearching) {
        _isSearching = false;
        _searchController.clear();
        _searchFocusNode.unfocus();
      }
      if (category == "Alle") {
        _visibleRestaurants = List.from(_allRestaurants);
      } else if (category == "Top Match") {
        _visibleRestaurants = List.from(_allRestaurants);
        _visibleRestaurants.sort((a, b) {
          final scoreA = MatchCalculator.calculate(_userProfile, a);
          final scoreB = MatchCalculator.calculate(_userProfile, b);
          return scoreB.compareTo(scoreA); // Descending
        });
      } else if (category == "Geöffnet") {
        _visibleRestaurants =
            _allRestaurants.where((r) => r['isOpenNow'] ?? true).toList();
      } else if (category == "Günstig") {
        _visibleRestaurants = _allRestaurants.where((r) {
          final price = (r['priceLevel'] ?? "").toString();
          return price == "€" || price == "Inexpensive";
        }).toList();
        if (_visibleRestaurants.isEmpty) {
          _visibleRestaurants = _allRestaurants
              .where((r) => !(r['priceLevel'] ?? "").toString().contains("€€€"))
              .toList();
        }
      } else {
        _visibleRestaurants = _allRestaurants
            .where((r) => (r['cuisines'] ?? "")
                .toString()
                .toLowerCase()
                .contains(category.toLowerCase()))
            .toList();
      }

      _generateMarkers();

      if (_visibleRestaurants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Keine Restaurants für '$category' gefunden."),
            duration: Duration(seconds: 1)));
      } else {
        if (_pageController.hasClients) _pageController.jumpToPage(0);
      }
    });
  }

  void _onSearchQueryChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _visibleRestaurants = List.from(_allRestaurants);
      } else {
        _visibleRestaurants = _allRestaurants.where((r) {
          final name = (r['name'] ?? '').toString().toLowerCase();
          final dishes = (r['lowercaseDishes'] as List?)?.cast<String>() ?? [];
          final cuisines = (r['cuisines'] ?? '').toString().toLowerCase();
          return name.contains(q) ||
              dishes.any((d) => d.contains(q)) ||
              cuisines.contains(q);
        }).toList();
      }
      _generateMarkers();
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    });
  }

  void _generateMarkers() {
    _markers = _visibleRestaurants.take(200).map((rest) {
      return Marker(
        markerId: MarkerId(rest['id']),
        position: LatLng(rest['latitude'] ?? 48.0, rest['longitude'] ?? 16.0),
        // Wir nutzen hier Standard-Marker eingefärbt, bis MarkerManager 100% steht
        icon: MarkerManager().customIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        onTap: () {
          final index = _visibleRestaurants.indexOf(rest);
          if (index != -1 && _pageController.hasClients) {
            _pageController.animateToPage(index,
                duration: 500.ms, curve: Curves.easeOutExpo);
          }
        },
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: _showMap,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchQueryChanged,
                autofocus: true,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Restaurant suchen…',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4)),
                  border: InputBorder.none,
                ),
              )
            : Text("Explore", style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: _showMap
            ? Colors.transparent
            : Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _isSearching
            ? IconButton(
                icon: Icon(Icons.adaptive.arrow_back),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                    _visibleRestaurants = List.from(_allRestaurants);
                    _generateMarkers();
                  });
                },
              )
            : null,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(CupertinoIcons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                  _selectedCategory = 'Alle';
                });
              },
            ),
          IconButton(
            icon: Icon(
                _showMap ? CupertinoIcons.list_bullet : CupertinoIcons.map),
            onPressed: () {
              setState(() => _showMap = !_showMap);
            },
          )
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _showMap ? _buildMapStack() : _buildListView(),
          ),
          Positioned(
            top: _showMap
                ? MediaQuery.of(context).padding.top + kToolbarHeight
                : 0,
            left: 0,
            right: 0,
            child: _buildCategories(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 45,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => _filterRestaurants(cat),
              child: AnimatedContainer(
                duration: 200.ms,
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).colorScheme.outline,
                      width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  cat,
                  style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn().slideY(begin: -0.5, end: 0);
  }

  Widget _buildMapStack() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _initialPositin,
          markers: _markers,
          style: _mapStyleString,
          zoomControlsEnabled: false,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            if (!_controller.isCompleted) {
              _controller.complete(controller);
              if (widget.targetLocation != null) {
                controller.animateCamera(
                    CameraUpdate.newLatLngZoom(widget.targetLocation!, 16));
              }
            }
          },
        ),
        if (!_isLoading && _visibleRestaurants.isNotEmpty)
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            height: 160,
            child: PageView.builder(
              controller: _pageController,
              physics: BouncingScrollPhysics(),
              itemCount: _visibleRestaurants.length,
              onPageChanged: (index) {
                final rest = _visibleRestaurants[index];
                _controller.future.then((c) => c.animateCamera(
                    CameraUpdate.newLatLng(
                        LatLng(rest['latitude'], rest['longitude']))));
              },
              itemBuilder: (context, index) {
                return _buildCard(_visibleRestaurants[index], isMapCard: true);
              },
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
          ),
      ],
    );
  }

  Widget _buildListView() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator.adaptive());
    }
    if (_visibleRestaurants.isEmpty) {
      return Center(
          child: Text("Keine Restaurants gefunden.",
              style: Theme.of(context).textTheme.bodyLarge));
    }
    return ListView.builder(
      padding: EdgeInsets.only(top: 70, bottom: 120),
      itemCount: _visibleRestaurants.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: _buildCard(_visibleRestaurants[index], isMapCard: false),
        );
      },
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildCard(Map<String, dynamic> rest, {bool isMapCard = false}) {
    final matchScore = MatchCalculator.calculate(_userProfile, rest);
    final imageUrl = rest['photoUrl'] != null && rest['photoUrl'].isNotEmpty
        ? rest['photoUrl']
        : "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=1000&auto=format&fit=crop";

    return GestureDetector(
      onTap: () {
        RestaurantDetailSheet.show(context, rest);
      },
      child: Container(
        margin:
            EdgeInsets.symmetric(horizontal: isMapCard ? 6 : 16, vertical: 0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface, // Solid Zinc
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context).colorScheme.outline), // Subtiler Rand
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bild
              SizedBox(
                width: 130,
                // Height is now defined by IntrinsicHeight
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          color: Theme.of(context).colorScheme.outline),
                      errorWidget: (_, __, ___) => Container(
                          color: Theme.of(context).colorScheme.outline,
                          child: Icon(Icons.restaurant)),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: matchScore > 80
                                    ? Colors.green
                                    : Theme.of(context).primaryColor)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("$matchScore%",
                                style: TextStyle(
                                    color: matchScore > 80
                                        ? Colors.green
                                        : Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            SizedBox(width: 4),
                            Text("Match",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(rest['name'] ?? "Restaurant",
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      SizedBox(height: 4),
                      Text(
                          "${rest['cuisines'] ?? 'Essen'} • ${rest['priceLevel'] ?? '€€'}",
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      Spacer(),
                      Row(
                        children: [
                          Icon(Icons.star_rounded,
                              color: Theme.of(context).primaryColor, size: 18),
                          SizedBox(width: 4),
                          Text("${rest['rating'] ?? 0.0}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface)),
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
