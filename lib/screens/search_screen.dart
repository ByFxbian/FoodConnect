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
import 'package:lottie/lottie.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String searchQuery = "";
  int selectedTab = 0; // 0 for restaurants, 1 for users
  bool isLoading = false;
  List<Map<String, dynamic>> searchResults = [];
  final DatabaseService databaseService = DatabaseService();
  final FirestoreService firestoreService = FirestoreService();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  List<String> _recentSearches = [];
  static const String _recentSearchesKey = 'recent_searches';

  // FILTER
  bool filterOpenNow = false;
  String? filterPriceLevel;
  //List<String> filterCuisines = [];
  double filterMinRating = 0.0;

  Map<String, List<String>> priceLevelMapping = {
    "€": ["Günstig", "Günstig - Mittelpreisig"],
    "€€": ["Mittelpreisig", "Günstig - Mittelpreisig", "Mittelpreisig - Gehobene Preisklasse"],
    "€€€": ["Gehoben", "Mittelpreisig - Gehobene Preisklasse", "Gehoben - Luxus"],
    "€€€€": ["Luxus", "Gehoben - Luxus"]
  };

  @override
  void initState() {
    super.initState();

    _searchFocusNode.addListener(_onFocusChange);
    _loadRecentSearches();

    _getRecommendations();
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if(!mounted) return;
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
      if(!_isSearchFocused && _searchController.text.isEmpty) {
        _getRecommendations();
      }
    });
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if(!mounted) return;
    setState(() {
      _recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
    });
  }

  Future<void> _addAndSaveFolderSearch(String query) async {
    if(query.trim().isEmpty) return;
    final String term = query.trim();

    List<String> updatedSearches = List<String>.from(_recentSearches);

    updatedSearches.remove(term);
    updatedSearches.insert(0, term);

    const int maxRecentSearches = 10;
    if (updatedSearches.length > maxRecentSearches) {
      updatedSearches = updatedSearches.sublist(0, maxRecentSearches);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, updatedSearches);

    if(!mounted) return;
    setState(() {
      _recentSearches = updatedSearches;
    });
  }

  Future<void> _removeRecentSearch(String term) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> updatedSearches = List<String>.from(_recentSearches);
    updatedSearches.remove(term);
    await prefs.setStringList(_recentSearchesKey, updatedSearches);

    if(!mounted) return;
    setState(() {
      _recentSearches = updatedSearches;
    });
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);

    if(!mounted) return;
    setState(() {
      _recentSearches = [];
    });
  }

  void _performSearch(String query) {
    if(query.trim().isEmpty) return;
    searchQuery = query.trim();
    _searchController.text = searchQuery;
    _searchFocusNode.unfocus();

    _addAndSaveFolderSearch(searchQuery);

    if(selectedTab == 0) {
      _searchRestaurants(searchQuery);
    } else {
      _searchUsers(searchQuery);
    }
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
        if(!mounted) return;
        setState(() {}); // Refresh the list on return from UserProfileScreen
      });
    }
  }

  Future<void> _getRecommendations() async {
    if(_isSearchFocused || _searchController.text.isNotEmpty) return;
    if(selectedTab == 1) {
      setState(() {
        searchResults = [];
        isLoading = false;
      });
      return;
    }
    setState(() {
      isLoading = true;
    });

    List<Map<String, dynamic>> recommendedRestaurants = await databaseService.getTopRatedRestaurants(limit: 5);
    if(!mounted) return;
    setState(() {
      searchResults = recommendedRestaurants;
      isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    if(!mounted) return;
    setState(() {
      searchQuery = query;

      if(query.isEmpty && _isSearchFocused) {
        searchResults = [];
        isLoading = false;
      } else if (query.isNotEmpty) {
        isLoading = true;
        if(selectedTab == 0) {
          _searchRestaurants(query);
        } else {
          _searchUsers(query);
        }
      } else {
        isLoading = false;
        _getRecommendations();
      }
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
                        //filterCuisines.clear();
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Text("Mindestbewertung: ${filterMinRating.toStringAsFixed(1)} ★"),
                  ),
                  Slider.adaptive(
                    value: filterMinRating,
                    min: 0.0,
                    max: 5.0,
                    divisions: 10,
                    label: filterMinRating.toStringAsFixed(1),
                    onChanged: (value) => setModalState(() => filterMinRating = value),
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
                  /*SizedBox(height: 10),
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
                  ),*/
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
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: /*(query) {
                setState(() {
                  searchQuery = query;
                });
                if (selectedTab == 0) {
                  _searchRestaurants(query);
                } else {
                  _searchUsers(query);
                }
              }*/
                _onSearchChanged,
              onSubmitted: (query) {
                _performSearch(query);
              },
              decoration: InputDecoration(
                hintText: "Suche nach Restaurants oder Nutzern...",
                prefixIcon: Icon(Platform.isIOS ? CupertinoIcons.search : Icons.search),
                suffixIcon: (selectedTab == 0 && searchQuery.isNotEmpty && !isLoading) 
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
              /*setState(() {
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
              });*/
              if(!mounted) return;
              setState(() {
                selectedTab = index;
                _searchController.clear();
                searchQuery = "";
                _searchFocusNode.unfocus();
                _getRecommendations();
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
            child: /*isLoading
                ? Center(child: /*CircularProgressIndicator.adaptive()*/ Lottie.asset('assets/animations/loading.json'))
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
                                            ? ResizeImage(NetworkImage(data['photoUrl'] ?? ""), height: 140, policy: ResizeImagePolicy.fit) 
                                            : ResizeImage(AssetImage("assets/icons/default_avatar.png"), height: 140, policy: ResizeImagePolicy.fit) as ImageProvider,
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
                      )*/
            _buildContentArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    if(_isSearchFocused && searchQuery.isEmpty) {
      return _buildRecentSearchesList();
    }

    else if (!_isSearchFocused && searchQuery.isEmpty && selectedTab == 0) {
      if(isLoading) return Center(child: Lottie.asset('assets/animations/loading.json'));
      if(searchResults.isEmpty) return Center(child: Text("Keine Empfehlungen verfügbar."));
      return _buildResultsList(title: "Empfehlungen für dich", icon: Icons.restaurant_menu);
    }

    else if (searchQuery.isNotEmpty) {
      if(isLoading) return Center(child: Lottie.asset('assets/animations/loading.json'));
      if(searchResults.isEmpty) return Center(child: Text("Keine Ergebnisse gefunden."));
      return _buildResultsList();
    }

    else {
      return Center(child: Text(""));
    }
  }

  Widget _buildRecentSearchesList() {
    if(_recentSearches.isEmpty) {
      return Center(child: Text("Keine letzten Suchen."));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Letzte Suchen",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600]),
              ),
              TextButton(
                onPressed: _clearRecentSearches,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text("Alle löschen", style: TextStyle(color: Colors.redAccent)),
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final term = _recentSearches[index];
              return ListTile(
                leading: Icon(Icons.history, color: Colors.grey[600]),
                title: Text(term),
                trailing: IconButton(
                  icon: Icon(Icons.close, size: 20, color: Colors.grey[600]),
                  onPressed: () => _removeRecentSearch(term),
                ),
                onTap: () {
                  _performSearch(term);
                },
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildResultsList({String? title, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(title != null)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8, left: 16, right: 16),
              child: Row(
                children: [
                  if(icon != null) Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    title,
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
                padding: EdgeInsets.zero,
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  var data = searchResults[index];
                  // *** TODO: Ergebnisdarstellung verbessern (Preis/Bewertung hinzufügen)
                  /*String subtitle;
                  ImageProvider leadingImage;

                  if(selectedTab == 0) {
                    subtitle = "Restaurant";
                    leadingImage = ResizeImage(AssetImage("assets/icons/default_avatar.png"), height: 140, policy: ResizeImagePolicy.fit) as ImageProvider;
                  } else {
                    subtitle = "Nutzer";
                    leadingImage = (data['photoUrl'] != null && data['photoUrl'].isNotEmpty) 
                      ? ResizeImage(NetworkImage(data['photoUrl']), height: 140, policy: ResizeImagePolicy.fit) 
                      : ResizeImage(AssetImage("assets/icons/default_avatar.png"), height: 140, policy: ResizeImagePolicy.fit) as ImageProvider;
                  }

                  return ListTile(
                    leading: selectedTab == 1 
                    ? CircleAvatar(
                      backgroundImage: leadingImage,
                    )
                    : null,
                    title: Text(data['name'] ?? "Unbekannt"),
                    subtitle: Text(subtitle),
                    onTap: () {
                      if(selectedTab == 0) {
                        _navigateToRestaurant(data);
                      } else {
                        _navigateToUserProfile(data['id']);
                      }

                      if(searchQuery.isNotEmpty) {
                        _addAndSaveFolderSearch(searchQuery);
                      }

                      _searchFocusNode.unfocus();
                    }
                  );*/
                  
                  if(selectedTab == 0 ) {
                    final String name = data['name'] ?? "Unbekanntes Restaurant";
                    final double rating = double.tryParse(data['rating'].toString()) ?? 0.0;
                    final String priceLevel = data['priceLevel'] ?? "";
                    final String? imageUrl = data['imageUrl'] ?? "";

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                          ? ResizeImage(NetworkImage(imageUrl), height: 140, policy: ResizeImagePolicy.fit) as ImageProvider
                          : null,
                        backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                        child: (imageUrl == null || imageUrl.isEmpty)
                          ? Icon(Icons.restaurant_menu, size: 30, color: Colors.grey[600])
                          : null,
                      ),
                      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Row(
                        children: [
                          if(rating > 0) ...[
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(rating.toString(), style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                          ],
                          if(rating > 0 && priceLevel.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text("•", style: TextStyle(color: Colors.grey[600])),
                            ),
                          if(priceLevel.isNotEmpty)
                            Flexible(
                              child: Text(
                                priceLevel,
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        _navigateToRestaurant(data);
                        if(searchQuery.isNotEmpty) {
                          _addAndSaveFolderSearch(searchQuery);
                        }
                        _searchFocusNode.unfocus();
                      },
                    );
                  } else {
                    final String name = data['name'] ?? "Unbekannter Nutzer";
                    final String? imageUrl = data['photoUrl'];

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                          ? ResizeImage(NetworkImage(imageUrl), height: 140, policy: ResizeImagePolicy.fit) as ImageProvider
                          : ResizeImage(AssetImage("assets/icons/default_avatar.png"), height: 140, policy: ResizeImagePolicy.fit) as ImageProvider,
                      ),
                      title: Text(name),
                      subtitle: Text("Nutzer"),
                      onTap: () {
                        _navigateToUserProfile(data['id']);
                        if(searchQuery.isNotEmpty) {
                          _addAndSaveFolderSearch(searchQuery);
                        }
                        _searchFocusNode.unfocus();
                      },
                    );
                  }
                },
              ),
            )
        ],
      ),
    );
  }

  void _searchRestaurants(String query) async {
    if(query.trim().isEmpty) {
      if(mounted) setState(() { searchResults = []; isLoading = false;});
      return;
    }

    if(!mounted) return;
    setState(() {
      isLoading = true;
    });

    // TODO: databaseService.searchRestaurantsWithFilters verwenden
    //Query firestoreQuery = FirebaseFirestore.instance.collection("restaurantDetails");
    Query firestoreQuery = FirebaseFirestore.instance.collection("restaurantDetails")
      .where("lowercaseDishes", arrayContains: query.toLowerCase());

    /*if(filterCuisines.isEmpty && filterPriceLevel == null && filterOpenNow == false) {
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
    */

    if(filterPriceLevel != null) {
      List<String> allowedPriceLevels = priceLevelMapping[filterPriceLevel!] ?? [];
      firestoreQuery = firestoreQuery.where("priceLevel", whereIn: allowedPriceLevels);
    }
    /*if(filterCuisines.isNotEmpty) {
      firestoreQuery = firestoreQuery.where("cuisines", arrayContainsAny: filterCuisines);
    }*/
    if(filterMinRating > 0) {
      firestoreQuery = firestoreQuery.where("rating", isGreaterThanOrEqualTo: filterMinRating);
    }

    QuerySnapshot querySnapshot = await firestoreQuery.limit(20).get();
    List<Map<String, dynamic>> results = querySnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;

      data['id'] = doc.id;
      return data;
    }).toList();

    if (!mounted) return;
    setState(() {
      searchResults = results;
      isLoading = false;
    });
  }

  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      if(mounted) setState(() { searchResults = []; isLoading = false;});
      return;
    }

    if(!mounted) return;
    setState(() {
      isLoading = true;
    });

    final snapshot = await FirebaseFirestore.instance
      .collection("users")
      .where("lowercaseName", isGreaterThanOrEqualTo: query.toLowerCase())
      .where("lowercaseName", isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
      .limit(10)
      .get();

    if(!mounted) return;
    setState(() {
      searchResults = snapshot.docs.map((doc) => doc.data()).toList();
      isLoading = false;
    });
  }

}