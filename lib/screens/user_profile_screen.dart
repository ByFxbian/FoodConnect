import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/screens/follower_list_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:lottie/lottie.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  UserProfileScreen({required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isFollowing = false;
  int followerCount = 0;
  int followingCount = 0;
  List<Map<String, dynamic>> userLists = [];
  final FirestoreService _firestoreService = FirestoreService();
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkFollowingStatus();
    _loadFollowCounts();
    _loadUserLists();
  }

  Future<void> _loadUserLists() async {
    List<Map<String, dynamic>> lists =
        await _firestoreService.getUserLists(widget.userId, onlyPublic: true);
    setState(() {
      userLists = lists;
    });
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

  Future<void> _toggleFollow() async {
    if (isFollowing) {
      await _firestoreService.unfollowUser(widget.userId);
    } else {
      await _firestoreService.followUser(widget.userId);
    }
    await _loadFollowCounts();
    setState(() {
      isFollowing = !isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
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
                ? Center(
                    child: /*CircularProgressIndicator()*/
                        Lottie.asset('assets/animations/loading.json'))
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
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              FollowerListScreen(
                                                  userId: widget.userId,
                                                  isFollowing: false)));
                                },
                                child: Column(
                                  children: [
                                    Text(
                                      followerCount.toString(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
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
                                          builder: (context) =>
                                              FollowerListScreen(
                                                  userId: widget.userId,
                                                  isFollowing: true)));
                                },
                                child: Column(
                                  children: [
                                    Text(
                                      followingCount.toString(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
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
                      if (userLists.isNotEmpty) ...[
                        _buildUserListsSection(),
                        SizedBox(height: 30),
                      ],
                      SizedBox(height: 120),
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
            backgroundImage:
                userData?['photoUrl'] != null && userData?['photoUrl'] != ""
                    ? ResizeImage(NetworkImage(userData?['photoUrl']),
                        height: 420, policy: ResizeImagePolicy.fit)
                    : ResizeImage(AssetImage("assets/icons/default_avatar.png"),
                        height: 420,
                        policy: ResizeImagePolicy.fit) as ImageProvider,
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

  Widget _buildUserListsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Öffentliche Listen",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary),
        ),
        Divider(color: Theme.of(context).colorScheme.primary),
        SizedBox(height: 8),
        SizedBox(
          height: 120, // Height for horizontal list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: userLists.length,
            itemBuilder: (context, index) {
              final list = userLists[index];
              return GestureDetector(
                onTap: () {
                  context.push('/lists/${list['id']}', extra: list);
                },
                child: Container(
                  width: 140,
                  margin: EdgeInsets.only(right: 12),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.format_list_bulleted,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32),
                      SizedBox(height: 8),
                      Text(
                        list['name'] ?? 'Unbenannte Liste',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
