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

  Map<String, List<String>> priceLevelMapping = {
    "€": ["Günstig", "Günstig - Mittelpreisig"],
    "€€": ["Mittelpreisig", "Günstig - Mittelpreisig", "Mittelpreisig - Gehobene Preisklasse"],
    "€€€": ["Gehoben", "Mittelpreisig - Gehobene Preisklasse", "Gehoben - Luxus"],
    "€€€€": ["Luxus", "Gehoben - Luxus"]
  };

  @override
  void initState() {
    super.initState();
    _getRecommendations();
  }

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

  Future<void> _getRecommendations() async {
    if(selectedTab == 1) return;
    setState(() {
      isLoading = true;
    });

    List<Map<String, dynamic>> recommendedRestaurants = await databaseService.getTopRatedRestaurants(limit: 5);

    setState(() {
      searchResults = recommendedRestaurants;
      isLoading = false;
    });
  }

  void _navigateToRestaurant(Map<String, dynamic> restaurant) {
    if(restaurant['latitude'] == null || restaurant['longitude'] == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(
            initialPage: 0,
            targetLocation: LatLng(
              restaurant['location'].latitude,
              restaurant['location'].longitude,
            ),
            selectedRestaurantId: restaurant['id'],
          ),
        ),
      );
    } else {
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
                  ElevatedButton(
                    onPressed: () {
                      setModalState(() {
                        filterOpenNow = false;
                        filterCuisines.clear();
                        filterPriceLevel = null;
                      });

                      Navigator.pop(context);
                      _searchRestaurants(searchQuery);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("Alle Filter zurücksetzen"),
                  ),
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
                } else {
                  if(selectedTab == 1) {
                    searchResults = [];
                  } else {
                    _getRecommendations();
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
                ? Center(child: CircularProgressIndicator.adaptive())
                : searchResults.isEmpty && searchQuery.isNotEmpty
                    ? Center(child: Text("Keine Ergebnisse gefunden"))
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if(searchQuery.isEmpty && searchResults.isNotEmpty && selectedTab == 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.restaurant_menu, color: Theme.of(context).colorScheme.primary, size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      "Empfehlungen für dich",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: searchResults.length,
                                itemBuilder: (context, index) {
                                  var data = searchResults[index];
                                  return ListTile(
                                    leading: selectedTab == 1 
                                      ? CircleAvatar(
                                          backgroundImage: selectedTab == 1 
                                            ? NetworkImage(data['photoUrl'] ?? "") 
                                            : AssetImage("assets/icons/default_avatar.png") as ImageProvider,
                                        ) 
                                      : null,
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
                            )
                          ],
                        ) ,
                      )
          ),
        ],
      ),
    );
  }

  void _searchRestaurants(String query) async {
    /*if(query.isEmpty) {
      _getRecommendations();
      return;
    }*/

    setState(() {
      isLoading = true;
    });

    Query firestoreQuery = FirebaseFirestore.instance.collection("restaurantDetails");

    if(filterCuisines.isEmpty && filterPriceLevel == null && filterOpenNow == false) {
      firestoreQuery = firestoreQuery.where("nameLowerCase", isGreaterThanOrEqualTo: query.toLowerCase());
    } else {
      firestoreQuery = firestoreQuery.where("nameLowerCase", isGreaterThanOrEqualTo: query.toLowerCase());

      if(filterPriceLevel != null) {
        List<String> allowedPriceLevels = priceLevelMapping[filterPriceLevel!] ?? [];
        firestoreQuery = firestoreQuery.where("priceLevel", whereIn: allowedPriceLevels);
      }

      if(filterCuisines.isNotEmpty) {
        firestoreQuery = firestoreQuery.where("cuisines", arrayContainsAny: filterCuisines);
      }

      if(filterOpenNow) {
        firestoreQuery = firestoreQuery.where("isOpenNow", isEqualTo: true);
      }
    }

    firestoreQuery.orderBy("nameLowerCase", descending: false);

    QuerySnapshot querySnapshot = await firestoreQuery.limit(10).get();
    List<Map<String, dynamic>> results = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    print(results);

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
      .where("lowercaseName", isGreaterThanOrEqualTo: query.toLowerCase())
      // ignore: prefer_interpolation_to_compose_strings
      .where("lowercaseName", isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
      .get();

    setState(() {
      searchResults = snapshot.docs.map((doc) => doc.data()).toList();
      isLoading = false;
    });
  }

}