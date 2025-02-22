import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/screens/home_screen.dart';
import 'package:foodconnect/screens/main_screen.dart';
import 'package:foodconnect/screens/user_profile_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String searchQuery = "";
  int selectedTab = 0;
  bool isLoading = false;
  List<DocumentSnapshot> searchResults = [];

  void _search() {
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
  }

  void _navigateToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(userId: userId),
      ),
    );
  }

  void _navigateToRestaurant(Map<String, dynamic> restaurant) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          onThemeChanged: (isDarkMode) {},
          initialPage: 0,
          targetLocation: LatLng(
            restaurant['location'].latitude,
            restaurant['location'].longitude,
          ),
          selectedRestaurantId: restaurant['id'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                _search();
              },
              decoration: InputDecoration(
                hintText: "Suche nach Restaurants oder Nutzern...",
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(height: 16),
          ToggleButtons(
            borderRadius: BorderRadius.circular(20),
            selectedColor: Colors.white,
            color: Colors.white70,
            fillColor: Colors.deepPurple,
            isSelected: [selectedTab == 0, selectedTab == 1],
            onPressed: (index) {
              setState(() {
                selectedTab = index;
                _search();
              });
            },
            children: [
              Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Restaurants")),
              Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Nutzer")),
            ],
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.deepPurple))
                : searchResults.isEmpty && searchQuery.isNotEmpty
                    ? Center(child: Text("Keine Ergebnisse gefunden", style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          var data = searchResults[index].data() as Map<String, dynamic>;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: data['photoUrl'] != null && data['photoUrl'].isNotEmpty
                                  ? NetworkImage(data['photoUrl'])
                                  : AssetImage("assets/icons/default_avatar.png") as ImageProvider,
                            ),
                            title: Text(
                              data['name'],
                              style: TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              selectedTab == 0 ? "Restaurant" : "Nutzer",
                              style: TextStyle(color: Colors.white70),
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

  Stream<QuerySnapshot> searchRestaurants() {
    return FirebaseFirestore.instance
      .collection("markers")
      .where("type", isEqualTo: "Restaurant")
      .where("name", isGreaterThanOrEqualTo: searchQuery)
      .snapshots();
  }

  Stream<QuerySnapshot> searchUsers() {
    return FirebaseFirestore.instance
        .collection("users")
        .where("name", isGreaterThanOrEqualTo: searchQuery)
        .snapshots();
  }
}