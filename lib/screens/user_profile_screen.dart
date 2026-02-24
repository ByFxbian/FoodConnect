import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/screens/follower_list_screen.dart';
import 'package:foodconnect/widgets/follow_button.dart';
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
      final data = userDoc.data() as Map<String, dynamic>;
      setState(() {
        userData = data;
        // Read denormalized counts from user doc
        followerCount = (data['followerCount'] as num?)?.toInt() ?? 0;
        followingCount = (data['followingCount'] as num?)?.toInt() ?? 0;
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
    if (mounted) {
      setState(() {
        followerCount = followers;
        followingCount = following;
      });
    }
  }

  Future<void> _checkFollowingStatus() async {
    bool following = await _firestoreService.isFollowingUser(widget.userId);
    if (mounted) {
      setState(() {
        isFollowing = following;
      });
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
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          userData?['name'] ?? "",
          key: ValueKey(userData?['name']),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: isLoading
                  ? Center(
                      child: Lottie.asset('assets/animations/loading.json'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        // Avatar
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
                                  : const AssetImage(
                                          "assets/icons/default_avatar.png")
                                      as ImageProvider,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Name
                        Text(
                          userData?['name'] ?? "Unbekannter Nutzer",
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 24),
                        // Follow Button
                        if (currentUser != null &&
                            currentUser!.uid != widget.userId)
                          SizedBox(
                            width: 140,
                            child: FollowButton(
                              targetUserId: widget.userId,
                              onToggled: _loadFollowCounts,
                            ),
                          ),
                        const SizedBox(height: 32),
                        // Stats row
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
                                      userId: widget.userId,
                                      isFollowing: false),
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
                                      userId: widget.userId, isFollowing: true),
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
                        const SizedBox(height: 120),
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
          "Öffentliche Listen",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: userLists.length,
            itemBuilder: (context, index) {
              final list = userLists[index];
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
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
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
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                        ),
                      ],
                    ),
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
