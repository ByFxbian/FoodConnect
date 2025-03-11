import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/main.dart';
import 'package:foodconnect/screens/main_screen.dart';
import 'package:foodconnect/screens/user_profile_screen.dart';
import 'package:foodconnect/services/database_service.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';

class SearchScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String searchQuery = "";
  int selectedTab = 0;
  bool isLoading = false;
  List<Map<String, dynamic>> searchResults = [];
  final DatabaseService databaseService = DatabaseService();
  final FirestoreService firestoreService = FirestoreService();

  // FILTER
  bool filterOpenNow = false;
  String? filterPriceLevel;
  List<String> filterCuisines = [];

  void _navigateToUserProfile(String userId) async {
    if(userId == FirebaseAuth.instance.currentUser!.uid) {
      if(navigatorKey.currentContext != null) {
        Navigator.popUntil(navigatorKey.currentContext!, (route) => route.isFirst);
      }

      await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          initialPage: 2,
        ),
      ));
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(userId: userId),
        ),
      ).then((_) {
        setState(() {}); // Refresh the list on return from UserProfileScreen
      });
    }
  }

  void _navigateToRestaurant(Map<String, dynamic> restaurant) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          initialPage: 0,
          targetLocation: LatLng(
            restaurant['latitude'],
            restaurant['longitude'],
          ),
          selectedRestaurantId: restaurant['id'],
        ),
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("Filter", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                  SwitchListTile.adaptive(
                    title: Text("Nur geöffnete Restaurants"),
                    value: filterOpenNow,
                    onChanged: (value) {
                      setModalState(() => filterOpenNow = value);
                    },
                  ),
                  DropdownButton<String>(
                    hint: Text("Preisniveau wählen"),
                    value: filterPriceLevel,
                    onChanged: (String? newValue) {
                      setModalState(() => filterPriceLevel = newValue);
                    },
                    items: ["€", "€€", "€€€", "€€€€"].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 5,
                    children: ["Italienisch", "Asiatisch", "Mexikanisch", "Amerikanisch", "Vegetarisch"]
                      .map((cuisine) => FilterChip(
                        label: Text(cuisine),
                        selected: filterCuisines.contains(cuisine),
                        onSelected: (bool selected) {
                          setModalState(() {
                            if(selected) {
                              filterCuisines.add(cuisine);
                            } else {
                              filterCuisines.remove(cuisine);
                            }
                          });
                        },
                      )).toList(),
                  ),
                  SizedBox(height: 20,),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _searchRestaurants(searchQuery);
                    },
                    child: Text("Filter anwenden"),
                  )
                ],
              ),
            );
          },
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (query) {
                setState(() {
                  searchQuery = query;
                });
                if (selectedTab == 0) {
                  _searchRestaurants(query);
                } else {
                  _searchUsers(query);
                }
              },
              decoration: InputDecoration(
                hintText: "Suche nach Restaurants oder Nutzern...",
                prefixIcon: Icon(Platform.isIOS ? CupertinoIcons.search : Icons.search),
                suffixIcon: selectedTab == 0
                    ? IconButton(
                        icon: Icon(Icons.filter_list),
                        onPressed: _showFilterModal,
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          ToggleButtons(
            borderRadius: BorderRadius.circular(20),
            selectedColor: Theme.of(context).colorScheme.onSurface,
            color: Theme.of(context).colorScheme.onSurface,
            fillColor: Theme.of(context).colorScheme.primary,
            isSelected: [selectedTab == 0, selectedTab == 1],
            onPressed: (index) {
              setState(() {
                selectedTab = index;
                if (searchQuery.isNotEmpty) {
                  if (selectedTab == 0) {
                    _searchRestaurants(searchQuery);
                  } else {
                    _searchUsers(searchQuery);
                  }
                }
              });
            },
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text("Restaurants"),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text("Nutzer"),
              ),
            ],
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : searchResults.isEmpty && searchQuery.isNotEmpty
                    ? Center(child: Text("Keine Ergebnisse gefunden"))
                    : ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          var data = searchResults[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(data['photoUrl'] ?? ""),
                            ),
                            title: Text(data['name']),
                            subtitle: Text(selectedTab == 0 ? "Restaurant" : "Nutzer"),
                            onTap: () {
                              if (selectedTab == 0) {
                                _navigateToRestaurant(data);
                              } else {
                                _navigateToUserProfile(data['id']);
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _searchRestaurants(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    //final results = await databaseService.searchRestaurants(query);
    final results = await databaseService.searchRestaurantsWithFilters(
      query: query,
      openNow: filterOpenNow,
      priceLevel: filterPriceLevel,
      cuisines: filterCuisines,
    );

    setState(() {
      searchResults = results;
      isLoading = false;
    });
  }

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    if(query.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final snapshot = await FirebaseFirestore.instance
      .collection("users")
      .where("name", isGreaterThanOrEqualTo: query)
      .get();

    setState(() {
      searchResults = snapshot.docs.map((doc) => doc.data()).toList();
      isLoading = false;
    });
  }

}