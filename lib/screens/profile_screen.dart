// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/screens/follower_list_screen.dart';
import 'package:foodconnect/screens/user_profile_screen.dart';
import 'package:foodconnect/screens/settings_screen.dart';

import 'package:foodconnect/services/database_service.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:foodconnect/widgets/follow_button.dart';
import 'package:lottie/lottie.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProfileScreen extends StatefulWidget {
  ProfileScreen();

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  int followerCount = 0;
  int followingCount = 0;
  List<Map<String, dynamic>> userLists = [];
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFollowCounts();
    _loadUserLists();
    FirestoreService().updateEmailVerificationStatus();
  }

  Future<void> _loadUserLists() async {
    if (user != null) {
      List<Map<String, dynamic>> lists =
          await _firestoreService.getUserLists(user!.uid);
      if (mounted) {
        setState(() {
          userLists = lists;
        });
      }
    }
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
    if (user != null) {
      await FirestoreService().updateEmailVerificationStatus();
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
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
  }

  Future<void> _sendVerificationEmail() async {
    try {
      await user?.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("E-Mail-Bestätigung erneut gesendet!")),
      );
      //Future.delayed(Duration(seconds: 10));
      await FirestoreService().updateEmailVerificationStatus();
    } catch (e) {
      print("Fehler beim Senden: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
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
            icon: Icon(
                Platform.isIOS ? CupertinoIcons.bell : Icons.notifications),
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
              icon: Icon(
                  Platform.isIOS ? CupertinoIcons.settings : Icons.settings,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 26),
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
                      child: /*CircularProgressIndicator.adaptive(),*/
                          Lottie.asset('assets/animations/loading.json'))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (userData?["emailVerified"] == false)
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .errorContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "E-Mail-Adresse unbestätigt",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onErrorContainer,
                                            fontWeight: FontWeight.w600),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _sendVerificationEmail,
                                  child: Text(
                                    "Senden",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.2),
                              width: 1,
                            ),
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: userData?['photoUrl'] != null &&
                                      userData?['photoUrl'] != ""
                                  ? NetworkImage(userData?['photoUrl'])
                                  : AssetImage(
                                          "assets/icons/default_avatar.png")
                                      as ImageProvider,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          userData?['name'] ?? "Unbekannter Nutzer",
                          key: ValueKey(userData?["name"]),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userData?['email'] ?? "Keine E-Mail vorhanden",
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatItem(
                              count: followerCount,
                              label: "Follower",
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FollowerListScreen(
                                      userId: user!.uid, isFollowing: false),
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),
                            _buildStatItem(
                              count: followingCount,
                              label: "Folgt",
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FollowerListScreen(
                                      userId: user!.uid, isFollowing: true),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        if (userLists.isNotEmpty) ...[
                          _buildUserListsSection(),
                          const SizedBox(height: 30),
                        ],
                        const SizedBox(height: 120), // Bottom nav padding
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required int count,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserListsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Meine Listen",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140, // Height for horizontal list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: userLists.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final list = userLists[index];
              return _buildListCard(list);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListCard(Map<String, dynamic> list) {
    return GestureDetector(
      onTap: () {
        context.push('/lists/${list['id']}', extra: list);
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.bookmark_border,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              Text(
                list['name'] ?? 'Unbenannte Liste',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
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
      if (Navigator.canPop(context)) {
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

  Future<void> _navigateToRestaurantFromNotification(
      String? restaurantId) async {
    if (restaurantId == null || restaurantId.isEmpty) {
      print("Keine Restaurant-ID für Navigation vorhanden.");
      return;
    }
    print("Navigiere zur Karte für Restaurant: $restaurantId");
    try {
      Map<String, dynamic>? restaurantData =
          await dbService.getRestaurantById(restaurantId);
      if (restaurantData != null &&
          restaurantData['latitude'] != null &&
          restaurantData['longitude'] != null) {
        LatLng targetLocation =
            LatLng(restaurantData['latitude'], restaurantData['longitude']);
        if (mounted) {
          context.go('/explore', extra: {
            'targetLocation': targetLocation,
            'selectedRestaurantId': restaurantId,
          });
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

    if (userId == null) {
      return Scaffold(
          appBar: AppBar(title: Text("Benachrichtigungen")),
          body: Center(child: Text("Bitte neu anmelden.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Benachrichtigungen"),
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
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
          if (!snapshot.hasData) {
            return Center(
                child: /*CircularProgressIndicator.adaptive()*/
                    Lottie.asset('assets/animations/loading.json'));
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

              if (type == 'follow') {
                String? actorName = notification['actorName'];
                String? actorImageUrl = notification['actorImageUrl'];
                String? actorId = notification['actorId'];
                Timestamp? timestamp = notification['timestamp'];

                String timeAgoString = "unbekannt";
                if (timestamp != null) {
                  timeAgoString =
                      timeago.format(timestamp.toDate(), locale: 'de_short');
                }

                if (actorName == null || actorId == null) {
                  return ListTile(
                      title: Text("Ungültige Follower-Benachrichtigung"));
                }

                return InkWell(
                  onTap: () {
                    _markAsread(doc.id);
                    _navigateToUser(actorId);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: (actorImageUrl != null &&
                                  actorImageUrl.isNotEmpty)
                              ? ResizeImage(NetworkImage(actorImageUrl),
                                  height: 420, policy: ResizeImagePolicy.fit)
                              : ResizeImage(
                                  AssetImage("assets/icons/default_avatar.png"),
                                  height: 420,
                                  policy:
                                      ResizeImagePolicy.fit) as ImageProvider,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: <TextSpan>[
                                TextSpan(
                                    text: actorName,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                TextSpan(text: ' folgt dir jetzt.'),
                                TextSpan(
                                  text: timeAgoString,
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13),
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
                String? actorName =
                    notification['actorName']; // Name des Reviewers
                String? actorImageUrl =
                    notification['actorImageUrl']; // Bild des Reviewers
                String? actorId = notification[
                    'actorId']; // ID des Reviewers (falls benötigt)
                String? title = notification[
                    'title']; // Sollte enthalten "X hat Y bewertet"
                String? body = notification[
                    'body']; // Sollte enthalten "Wurde mit Z Sternen bewertet"
                Timestamp? timestamp = notification['timestamp'];
                bool isRead = notification['isRead'] ?? false;
                String? restaurantId = notification['relevantId'];

                String timeAgoString = "";
                if (timestamp != null) {
                  try {
                    timeAgoString =
                        timeago.format(timestamp.toDate(), locale: 'de_short');
                  } catch (e) {
                    timeAgoString = "?";
                  } // Fallback
                }

                return InkWell(
                  onTap: () {
                    _markAsread(doc.id);
                    _navigateToRestaurantFromNotification(
                        restaurantId); // Navigiere zum Restaurant
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        // Bild des Reviewers
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: (actorImageUrl != null &&
                                  actorImageUrl.isNotEmpty)
                              ? NetworkImage(actorImageUrl)
                              : null,
                          child:
                              (actorImageUrl == null || actorImageUrl.isEmpty)
                                  ? Icon(Icons.person, size: 24)
                                  : null,
                        ),
                        SizedBox(width: 12),
                        // Text (Titel, Body, Zeit)
                        Expanded(
                          child: Column(
                            // Titel und Body/Zeit untereinander
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title ??
                                    "Neue Bewertung", // Verwende den gespeicherten Titel
                                style: TextStyle(
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold),
                                maxLines: 2, // Max 2 Zeilen für Titel
                                overflow:
                                    TextOverflow.ellipsis, // ... wenn länger
                              ),
                              SizedBox(height: 4),
                              Text(
                                "${body ?? ''} • $timeAgoString", // Kombiniere Body und Zeit
                                style: TextStyle(
                                    color: isRead
                                        ? Colors.grey[600]
                                        : Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color
                                            ?.withValues(alpha: 0.8),
                                    fontSize: 13),
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
                  title: Text(
                      notification['title'] ?? 'Unbekannte Benachrichtigung'),
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
