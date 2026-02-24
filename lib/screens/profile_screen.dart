// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodconnect/screens/follower_list_screen.dart';
import 'package:foodconnect/screens/user_profile_screen.dart';
import 'package:foodconnect/screens/search_screen.dart';
import 'package:foodconnect/screens/settings_screen.dart';

import 'package:foodconnect/services/database_service.dart';
import 'package:foodconnect/services/firestore_service.dart';
import 'package:foodconnect/widgets/follow_button.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFollowCounts();
    FirestoreService().updateEmailVerificationStatus();
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
                Platform.isIOS
                    ? CupertinoIcons.person_add
                    : Icons.person_search,
                color: Theme.of(context).colorScheme.onSurface,
                size: 26),
            tooltip: 'Nutzer suchen',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
          ),
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
                        // Lists section — real-time stream
                        if (user != null)
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream:
                                _firestoreService.streamUserLists(user!.uid),
                            builder: (context, listSnap) {
                              final lists = listSnap.data ?? [];
                              if (lists.isEmpty) return const SizedBox.shrink();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildUserListsSection(lists),
                                  const SizedBox(height: 30),
                                ],
                              );
                            },
                          ),
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

  Widget _buildUserListsSection(List<Map<String, dynamic>> lists) {
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
            itemCount: lists.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final list = lists[index];
              return _buildListCard(list);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListCard(Map<String, dynamic> list) {
    final coverUrl = list['coverUrl'] as String?;
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;

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
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover area
            Expanded(
              child: hasCover
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: Center(
                          child: Icon(Icons.bookmark_border,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28),
                        ),
                      ),
                    )
                  : Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Icon(Icons.bookmark_border,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28),
                      ),
                    ),
            ),
            // Name label
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                list['name'] ?? 'Unbenannte Liste',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
              ),
            ),
          ],
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

              // Shared fields
              String? actorName = notification['actorName'];
              String? actorImageUrl = notification['actorImageUrl'];
              String? actorId = notification['actorId'];
              Timestamp? timestamp = notification['timestamp'];
              bool isRead = notification['isRead'] ?? false;

              String timeAgoString = "";
              if (timestamp != null) {
                try {
                  timeAgoString =
                      timeago.format(timestamp.toDate(), locale: 'de_short');
                } catch (_) {
                  timeAgoString = "";
                }
              }

              // ── Follow notification ──
              if (type == 'follow') {
                if (actorName == null || actorId == null) {
                  return const SizedBox.shrink();
                }

                return InkWell(
                  onTap: () {
                    _markAsread(doc.id);
                    _navigateToUser(actorId);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: isRead
                          ? Colors.transparent
                          : Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.06),
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.1),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _navigateToUser(actorId),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundImage: (actorImageUrl != null &&
                                    actorImageUrl.isNotEmpty)
                                ? ResizeImage(NetworkImage(actorImageUrl),
                                    height: 420, policy: ResizeImagePolicy.fit)
                                : ResizeImage(
                                        AssetImage(
                                            "assets/icons/default_avatar.png"),
                                        height: 420,
                                        policy: ResizeImagePolicy.fit)
                                    as ImageProvider,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: actorName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const TextSpan(text: ' folgt dir jetzt.'),
                                  ],
                                ),
                              ),
                              if (timeAgoString.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  timeAgoString,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5)),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 90,
                          height: 35,
                          child: FollowButton(targetUserId: actorId),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // ── Generic fallback ──
              return InkWell(
                onTap: () => _markAsread(doc.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 14.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.1),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: Icon(Icons.notifications_outlined,
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification['title'] ?? 'Benachrichtigung',
                              style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if ((notification['body'] ?? '').isNotEmpty ||
                                timeAgoString.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                [
                                  if ((notification['body'] ?? '').isNotEmpty)
                                    notification['body'],
                                  if (timeAgoString.isNotEmpty) timeAgoString,
                                ].join(' • '),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
