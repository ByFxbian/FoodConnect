import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/screens/main_screen.dart';
import 'package:foodconnect/screens/user_profile_screen.dart';
import 'package:foodconnect/services/database_service.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  /*void _search() {
    setState(() {
      isLoading = true;
    });

    Stream<QuerySnapshot> stream = selectedTab == 0 ? searchRestaurants() : searchUsers();

    stream.listen((snapshot) {
      setState(() {
        searchResults = snapshot.docs;
        isLoading = false;
      });
    });
  }*/

  void _navigateToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(userId: userId),
      ),
    );
  }

  void _navigateToRestaurant(Map<String, dynamic> restaurant) {
    print(restaurant['latitude']);
    print(restaurant['longitude']);
    print(restaurant['id']);
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
                if(selectedTab == 0) {
                  _searchRestaurants(query);
                } else {
                  _searchUsers(query);
                }
              },
              decoration: InputDecoration(
                hintText: "Suche nach Restaurants oder Nutzern...",
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface),
                filled: true,
                fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
                if(searchQuery.isNotEmpty) {
                  if(selectedTab == 0) {
                    _searchRestaurants(searchQuery);
                  } else {
                    _searchUsers(searchQuery);
                  }
                }
              });
            },
            children: [
              Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Restaurants", style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
              Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Nutzer", style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
            ],
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                : searchResults.isEmpty && searchQuery.isNotEmpty
                    ? Center(child: Text("Keine Ergebnisse gefunden", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)))
                    : ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          var data = searchResults[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: data['photoUrl'] != null && data['photoUrl'].isNotEmpty
                                  ? NetworkImage(data['photoUrl'])
                                  : AssetImage("assets/icons/default_avatar.png") as ImageProvider,
                            ),
                            title: Text(
                              data['name'],
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
                            subtitle: Text(
                              selectedTab == 0 ? "Restaurant" : "Nutzer",
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
                            onTap: () {
                              if(selectedTab == 0) {
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
    if(query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    final results = await databaseService.searchRestaurants(query);

    setState(() {
      searchResults = results;
      isLoading = false;
    });
  }

  void _searchUsers(String query) async {
    if(query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

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