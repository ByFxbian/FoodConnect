import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/screens/follower_list_screen.dart';
import 'package:foodconnect/screens/main_screen.dart';
import 'package:foodconnect/services/database_service.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class UserProfileScreen extends StatefulWidget{
  final String userId;

  UserProfileScreen({ required this.userId});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isFollowing = false;
  int followerCount = 0;
  int followingCount = 0;
  List<Map<String, dynamic>> userReviews = [];
  bool showAllReviews = false;
  final FirestoreService _firestoreService = FirestoreService();
  final DatabaseService _databaseService = DatabaseService();
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkFollowingStatus();
    _loadFollowCounts();
    _loadUserReviews();
  }

  Future<void> _loadUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.userId)
        .get();

    if (userDoc.exists) {
      setState(() {
        userData = userDoc.data() as Map<String, dynamic>;
        isLoading = false;
      });
    } else {
      setState(() {
        userData = {};
        isLoading = true;
      });
    }
  }

  Future<void> _loadFollowCounts() async {
    int followers = await _firestoreService.getFollowerCount(widget.userId);
    int following = await _firestoreService.getFollowingCount(widget.userId);
    setState(() {
      followerCount = followers;
      followingCount = following;
    });
  }

  Future<void> _checkFollowingStatus() async {
    bool following = await _firestoreService.isFollowingUser(widget.userId);
    setState(() {
      isFollowing = following;
    });
  }

  Future<void> _loadUserReviews() async {
    List<Map<String, dynamic>> reviews = await _firestoreService.getUserReviews(widget.userId);
    setState(() {
      userReviews = reviews;
    });
  }

  Future<void> _toggleFollow() async {
    if(isFollowing) {
      await _firestoreService.unfollowUser(widget.userId);
    } else {
      await _firestoreService.followUser(widget.userId);
    }   
     await _loadFollowCounts();
    setState(() {
      isFollowing = !isFollowing;
    });
  }  

  String _pixelateEmail(String email) {
    if (!email.contains("@")) return email;
    List<String> parts = email.split("@");
    String domain = parts.last;
    String pixelated = parts.first.length > 3
        ? "${parts.first.substring(0, 3)}***"
        : "***";
    return "$pixelated@$domain";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          userData?['name'] ?? "Unbekannter Nutzer",
          key: ValueKey(userData?['name']),
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: isLoading
                ? Center(child: /*CircularProgressIndicator()*/ Lottie.asset('assets/animations/loading.json'))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._buildProfileInfo(),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(context, 
                                  MaterialPageRoute(builder: (context) => FollowerListScreen(userId: widget.userId, isFollowing: false)));
                                },
                                child: Column(
                                  children: [
                                    Text(
                                      followerCount.toString(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      "Follower",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                          SizedBox(width: 20),
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(context, 
                                  MaterialPageRoute(builder: (context) => FollowerListScreen(userId: widget.userId, isFollowing: true)));
                                },
                                child: Column(
                                  children: [
                                    Text(
                                      followingCount.toString(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      "Folgt",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      _buildTasteProfileSection(userData?['tasteProfile']),
                      SizedBox(height: 30),
                      _buildUserReviewsSection(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProfileInfo() {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // TODO: Bild zum Anklicken & Zoomen machen wie bei Instagram.
          CircleAvatar(
            radius: 60,
            backgroundImage: userData?['photoUrl'] != null &&
                    userData?['photoUrl'] != ""
                ? ResizeImage(NetworkImage(userData?['photoUrl']), height: 420, policy: ResizeImagePolicy.fit)
                : ResizeImage(AssetImage("assets/icons/default_avatar.png"), height: 420, policy: ResizeImagePolicy.fit) as ImageProvider,
          ),
          SizedBox(width: 15),
          ElevatedButton(
            onPressed: _toggleFollow,
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              isFollowing ? "Entfolgen" : "Folgen",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildUserReviewsSection() {
    List<Map<String, dynamic>> displayedReviews =
        showAllReviews ? userReviews : userReviews.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "⭐ Nutzerbewertungen",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary),
        ),
        Divider(color: Theme.of(context).colorScheme.primary),
        if (displayedReviews.isEmpty)
          Text(
            "Keine Bewertungen vorhanden.",
            style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ...displayedReviews.map((review) {
          Timestamp? timestamp = review['timestamp'];
          String timeAgoString = "";
          if(timestamp != null) {
            try {
              timeAgoString = timeago.format(timestamp.toDate(), locale: 'de_short');
            } catch (e) {
              print("Fehler beim Formatieren des Zeitstempels: $e");
              timeAgoString = DateFormat('dd.MM.yy').format(timestamp.toDate());
            }
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: userData?['photoUrl'] != null &&
                      userData?['photoUrl'] != ""
                  ? ResizeImage(NetworkImage(userData?['photoUrl']), height: 140, policy: ResizeImagePolicy.fit)
                  : ResizeImage(AssetImage("assets/icons/default_avatar.png"), height: 140, policy: ResizeImagePolicy.fit) as ImageProvider,
            ),
            title: Text(review['restaurantName'] ?? 'Unbekanntes Restaurant'),
            subtitle: Text("${review['rating']} ⭐: ${review['comment']}",
                style: TextStyle(fontSize: 14)),
            trailing: Text(timeAgoString.isNotEmpty ? " • $timeAgoString" : ""),
            onTap: () => _navigateToRestaurant(review["restaurantId"]),
          );
        }).toList(),
          if (userReviews.length > 5)
          TextButton(
            onPressed: () => setState(() => showAllReviews = !showAllReviews),
            child: Text(showAllReviews ? "Weniger anzeigen" : "Mehr anzeigen"),
          ),
         /*=> ListTile(
              leading: CircleAvatar(
                backgroundImage: userData?['photoUrl'] != null &&
                    userData?['photoUrl'] != ""
                  ? NetworkImage(userData?['photoUrl'])
                  : AssetImage("assets/icons/default_avatar.png") as ImageProvider,
              ),
              title: Text(review['restaurantName'] ?? 'Unbekanntes Restaurant'),
              subtitle: Text("${review['rating']} ⭐: ${review['comment']}",
                  style: TextStyle(fontSize: 14)),
              onTap: () => _navigateToRestaurant(review["restaurantId"]),
            ))*/
      ],
    );
  }

  void _navigateToRestaurant(String restaurant) async {
    Map<String, dynamic>? restaurantData = await _databaseService.getRestaurantById(restaurant);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          initialPage: 0,
          targetLocation: LatLng(
            restaurantData?['latitude'],
            restaurantData?['longitude'],
          ),
          selectedRestaurantId: restaurant,
        ),
      ),
    );
  }

  Widget _buildTasteProfileSection(Map<String, dynamic>? tasteProfile) {
    if (tasteProfile == null || tasteProfile.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🍽️ Geschmacksprofil",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary),
          ),
          Divider(color: Theme.of(context).colorScheme.primary),
          Text(
            "Keine Informationen vorhanden.",
            style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "🍽️ Geschmacksprofil",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary),
        ),
        Divider(color: Theme.of(context).colorScheme.primary),
        ...tasteProfile.entries.map((entry) {
          return _buildTasteProfileRow(_mapKeyToLabel(entry.key), entry.value);
        // ignore: unnecessary_to_list_in_spreads
        }).toList(),
      ],
    );
  }

  Widget _buildTasteProfileRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? "Nicht angegeben",
              style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  String _mapKeyToLabel(String key) {
    switch (key) {
      case "favoriteCuisine":
        return "🌎 Lieblingsküche:";
      case "dietType":
        return "🥗 Ernährung:";
      case "spiceLevel":
        return "🌶️ Schärfe-Level:";
      case "allergies":
        return "🚫 Allergien:";
      case "favoriteTaste":
        return "😋 Lieblingsgeschmack:";
      case "dislikedFoods":
        return "🚫 Mag nicht:";
      default:
        return key;
    }
  }
}