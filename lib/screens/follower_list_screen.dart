import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodconnect/screens/user_profile_screen.dart';
import 'package:go_router/go_router.dart';

class FollowerListScreen extends StatelessWidget {
  final String userId;
  final bool isFollowing;

  const FollowerListScreen(
      {required this.userId, required this.isFollowing, super.key});

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
          isFollowing ? 'Folgt' : 'Follower',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(isFollowing ? 'following' : 'followers')
            .orderBy('followedAt', descending: true)
            .limit(30)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFollowing ? Icons.person_search : Icons.group_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isFollowing
                        ? 'Folgt noch niemanden.'
                        : 'Noch keine Follower.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 72,
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
            ),
            itemBuilder: (context, index) {
              String targetUserId = docs[index].id;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(targetUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      leading: CircleAvatar(radius: 24),
                      title: SizedBox(
                        height: 14,
                        width: 100,
                      ),
                    );
                  }
                  var userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Container(
                      width: 48,
                      height: 48,
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
                                  (userData?['photoUrl'] as String).isNotEmpty
                              ? NetworkImage(userData!['photoUrl'])
                              : const AssetImage(
                                      'assets/icons/default_avatar.png')
                                  as ImageProvider,
                        ),
                      ),
                    ),
                    title: Text(
                      userData?['name'] ?? 'Unbekannter Nutzer',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3),
                      size: 20,
                    ),
                    onTap: () {
                      if (targetUserId ==
                          FirebaseAuth.instance.currentUser!.uid) {
                        if (context.mounted) context.go('/profile');
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UserProfileScreen(userId: targetUserId),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
