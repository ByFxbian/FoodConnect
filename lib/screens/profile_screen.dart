// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/screens/follower_list_screen.dart';
import 'package:foodconnect/screens/main_screen.dart';
import 'package:foodconnect/screens/settings_screen.dart';
import 'package:foodconnect/screens/taste_profile_screen.dart';
import 'package:foodconnect/screens/user_profile_screen.dart';
import 'package:foodconnect/services/database_service.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:platform_maps_flutter/platform_maps_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProfileScreen extends StatefulWidget {

  ProfileScreen();

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  int followerCount = 0;
  int followingCount = 0;
  int reviewCount = 0;
  List<Map<String, dynamic>> userReviews = [];
  bool showAllReviews = false;
  final FirestoreService _firestoreService = FirestoreService();
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFollowCounts();
    _loadUserReviews();
    _loadReviewCount();
    FirestoreService().updateEmailVerificationStatus();
  }

  Future<void> _loadReviewCount() async {
    int count = await _firestoreService.getUserReviewCount(user!.uid);
    setState(() {
      reviewCount = count;
    });
  }

  Future<void> _loadFollowCounts() async {
    int followers = await _firestoreService.getFollowerCount(user!.uid);
    int following = await _firestoreService.getFollowingCount(user!.uid);
    setState(() {
      followerCount = followers;
      followingCount = following;
    });
  }

  Future<void> _loadUserData() async {
    if(user != null) {
      await FirestoreService().updateEmailVerificationStatus();
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();

      if(userDoc.exists) {
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
  }

  Future<void> _loadUserReviews() async {
    List<Map<String, dynamic>> reviews =
        await _firestoreService.getUserReviews(user!.uid);
    setState(() {
      userReviews = reviews;
    });
  }

  Future<void> _sendVerificationEmail() async {
    try {
      await user?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("E-Mail-Bestätigung erneut gesendet!")),
      );
      //Future.delayed(Duration(seconds: 10));
      await FirestoreService().updateEmailVerificationStatus();
    } catch (e) {
      print("Fehler beim Senden: $e");
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Profil",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Platform.isIOS ? CupertinoIcons.bell : Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(Platform.isIOS ? CupertinoIcons.settings : Icons.settings,
                  color: Theme.of(context).colorScheme.onSurface, size: 26),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<bool>(
                    builder: (context) => SettingsScreen(
                      onUsernameChanged: _loadUserData,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: isLoading
                  ? Center(
                      child: /*CircularProgressIndicator.adaptive(),*/Lottie.asset('assets/animations/loading.json')
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if(userData?["emailVerified"] == false)
                          Container(
                            color: Colors.orangeAccent,
                            padding: EdgeInsets.all(10),
                            margin: EdgeInsets.all(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "Bitte bestätige deine E-Mail-Adresse!",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _sendVerificationEmail,
                                  child: Text("Erneut senden", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: userData?['photoUrl'] != null &&
                                  userData?['photoUrl'] != ""
                              ? ResizeImage(NetworkImage(userData?['photoUrl']), height: 420, policy: ResizeImagePolicy.fit)
                              : ResizeImage(AssetImage("assets/icons/default_avatar.png"), height: 420, policy: ResizeImagePolicy.fit)
                                  as ImageProvider,
                        ),
                        SizedBox(height: 20),
                        Text(
                          userData?['name'] ?? "Unbekannter Nutzer",
                          key: ValueKey(userData?["name"]),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          userData?['email'] ?? "Keine E-Mail vorhanden",
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FollowerListScreen(userId: user!.uid, isFollowing: false),
                                      ),
                                    );
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FollowerListScreen(userId: user!.uid, isFollowing: true),
                                      ),
                                    );
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
                            SizedBox(width: 20),
                            Column(
                              children: [
                                Text(
                                  reviewCount.toString(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  "Bewertungen",
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
                          ],
                        ),
                        SizedBox(height: 30),
                        _buildTasteProfileSection(userData?['tasteProfile']),
                        SizedBox(height: 20),
                        _buildUserReviewsSection(),
                        SizedBox(height: 100),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserReviewsSection() {
    List<Map<String, dynamic>> displayedReviews =
        showAllReviews ? userReviews : userReviews.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "⭐ Bewertungen",
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
            title: Text(review['restaurantName'] ?? 'Unbekanntes Restaurant'),
            subtitle: Text("${review['rating']} ⭐: ${review['comment']}",
                style: TextStyle(fontSize: 14)),
            trailing: Text(timeAgoString.isNotEmpty ? " • $timeAgoString" : ""),
            isThreeLine: true,
            onTap: () => _navigateToRestaurant(review['restaurantId']),
          );
        // ignore: unnecessary_to_list_in_spreads
        }).toList(),
          if (userReviews.length > 5)
          TextButton(
            onPressed: () => setState(() => showAllReviews = !showAllReviews),
            child: Text(showAllReviews ? "Weniger anzeigen" : "Mehr anzeigen"),
          ),
        ]
    );
  }

  Widget _buildTasteProfileSection(Map<String, dynamic>? tasteProfile) {
    bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    void _navigateToEditProfile() async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TasteProfileScreen(
            userId: user!.uid,
            initialProfileData: tasteProfile,
          ),
        ),
      );

      _loadUserData();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Verteilt Elemente
          children: [
            Text(
              "🍽️ Geschmacksprofil",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary),
            ),
            IconButton(
               icon: Icon(Platform.isIOS ? CupertinoIcons.pencil : Icons.edit, size: 20),
               color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
               onPressed: _navigateToEditProfile,
               tooltip: 'Geschmacksprofil bearbeiten',
            )
            // -----------------------
          ],
        ),
        isIOS ? Divider(color: Theme.of(context).colorScheme.primary) : Divider(color: Theme.of(context).colorScheme.primary),
        if (tasteProfile == null || tasteProfile.isEmpty)
           Padding( // Padding für Konsistenz
             padding: const EdgeInsets.symmetric(vertical: 8.0),
             child: Text(
                "Keine Informationen vorhanden.",
                style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
           )
        else
          ...tasteProfile.entries
            // Nur Einträge anzeigen, die einen Wert haben (optional, für Sauberkeit)
            .where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
            .map((entry) {
                 return _buildTasteProfileRow(_mapKeyToLabel(entry.key), entry.value);
               // ignore: unnecessary_to_list_in_spreads
               }).toList(), // .toList() kann hier weg, wenn spread (...) verwendet wird

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

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
   final DatabaseService dbService = DatabaseService();

  Future<void> _markAsread(String docId) async {
    try {
      await _db.collection("notifications").doc(docId).update({'isRead': true});
    } catch (e) {
      print("Fehler beim Markieren als gelesen: $e");
    }
  }

  void _navigateToUser(String userId) {
    if (userId == _auth.currentUser?.uid) {
      if(Navigator.canPop(context)){
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(userId: userId),
        ),
      );
    }
  }

  Future<void> _navigateToRestaurantFromNotification(String? restaurantId) async {
    if(restaurantId == null || restaurantId.isEmpty) {
      print("Keine Restaurant-ID für Navigation vorhanden.");
      return;
    }
    print("Navigiere zur Karte für Restaurant: $restaurantId");
    try {
      Map<String, dynamic>? restaurantData = await dbService.getRestaurantById(restaurantId);
      if(restaurantData != null && restaurantData['latitude'] != null && restaurantData['longitude'] != null) {
        LatLng targetLocation = LatLng(restaurantData['latitude'], restaurantData['longitude']);
        if(mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => MainScreen(
                    initialPage: 0,
                    targetLocation: targetLocation,
                    selectedRestaurantId: restaurantId,
                ),
            ),
            (route) => route.isFirst,
          );
        }
      } else {
        print("Restaurant-Daten für Navigation nicht gefunden.");
      }
    } catch (e) {
      print("🔥 Fehler bei Navigation zum Restaurant: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String? userId = _auth.currentUser?.uid;

    if(userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Benachrichtigungen")),
        body: Center(child: Text("Bitte neu anmelden."))
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Benachrichtigungen"),
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
          .collection("notifications")
          .where("recipientUserId", isEqualTo: userId)
          .orderBy("timestamp", descending: true)
          .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
             return Center(child: Text("Fehler beim Laden: ${snapshot.error}"));
          }
          if(!snapshot.hasData) {
            return Center(child: /*CircularProgressIndicator.adaptive()*/ Lottie.asset('assets/animations/loading.json'));
          } 
          var notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
             return Center(child: Text("Keine neuen Benachrichtigungen."));
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var doc = notifications[index];
              var notification = doc.data() as Map<String, dynamic>;

              String type = notification['type'] ?? '';

              if(type == 'follow') {
                String? actorName = notification['actorName'];
                String? actorImageUrl = notification['actorImageUrl'];
                String? actorId = notification['actorId'];
                Timestamp? timestamp = notification['timestamp'];

                String timeAgoString = "unbekannt";
                if(timestamp != null) {
                  timeAgoString = timeago.format(timestamp.toDate(), locale: 'de_short');
                }

                if (actorName == null || actorId == null) {
                  return ListTile(title: Text("Ungültige Follower-Benachrichtigung"));
                }

                return InkWell(
                  onTap: () {
                    _markAsread(doc.id);
                    _navigateToUser(actorId);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: (actorImageUrl != null && actorImageUrl.isNotEmpty)
                              ? ResizeImage(NetworkImage(actorImageUrl), height: 420, policy: ResizeImagePolicy.fit)
                              : ResizeImage(AssetImage("assets/icons/default_avatar.png"), height: 420, policy: ResizeImagePolicy.fit) as ImageProvider,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: <TextSpan>[
                                TextSpan(text: actorName, style: TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: ' folgt dir jetzt.'),
                                TextSpan(
                                  text: timeAgoString,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        SizedBox(
                          width: 90,
                          height: 35,
                          child: FollowButton(
                            targetUserId: actorId,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (type == 'review') {
                String? actorName = notification['actorName']; // Name des Reviewers
                String? actorImageUrl = notification['actorImageUrl']; // Bild des Reviewers
                String? actorId = notification['actorId']; // ID des Reviewers (falls benötigt)
                String? title = notification['title']; // Sollte enthalten "X hat Y bewertet"
                String? body = notification['body']; // Sollte enthalten "Wurde mit Z Sternen bewertet"
                Timestamp? timestamp = notification['timestamp'];
                bool isRead = notification['isRead'] ?? false;
                String? restaurantId = notification['relevantId'];

                String timeAgoString = "";
                if (timestamp != null) {
                  try {
                    timeAgoString = timeago.format(timestamp.toDate(), locale: 'de_short');
                  } catch(e) { timeAgoString = "?"; } // Fallback
                }

                return InkWell(
                  onTap: () {
                    _markAsread(doc.id);
                    _navigateToRestaurantFromNotification(restaurantId); // Navigiere zum Restaurant
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                        children: [
                          // Bild des Reviewers
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: (actorImageUrl != null && actorImageUrl.isNotEmpty)
                                ? NetworkImage(actorImageUrl) : null,
                            child: (actorImageUrl == null || actorImageUrl.isEmpty)
                                ? Icon(Icons.person, size: 24) : null,
                          ),
                          SizedBox(width: 12),
                          // Text (Titel, Body, Zeit)
                          Expanded(
                            child: Column( // Titel und Body/Zeit untereinander
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    title ?? "Neue Bewertung", // Verwende den gespeicherten Titel
                                    style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                                    maxLines: 2, // Max 2 Zeilen für Titel
                                    overflow: TextOverflow.ellipsis, // ... wenn länger
                                ),
                                SizedBox(height: 4),
                                Text(
                                    "${body ?? ''} • $timeAgoString", // Kombiniere Body und Zeit
                                    style: TextStyle(color: isRead ? Colors.grey[600] : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8), fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                        ],
                      ),
                  ),
                );

              } else {
                return ListTile(
                  leading: Icon(Icons.notifications_none),
                  title: Text(notification['title'] ?? 'Unbekannte Benachrichtigung'),
                  subtitle: Text(notification['body'] ?? ''),
                );
              }

              /*return ListTile(
                title: Text(notification['title'] ?? "Benachrichtigung"),
                subtitle: Text(notification['body'] ?? ""),
                trailing: Text(notification['timestamp']?.toDate().toString() ?? ""),
              );*/
            },
          );
        },
      ),
    );
  }
}