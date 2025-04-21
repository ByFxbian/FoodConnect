import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodconnect/screens/main_screen.dart';
import 'package:foodconnect/screens/user_profile_screen.dart';
import 'package:lottie/lottie.dart';

class FollowerListScreen extends StatelessWidget {
  final String userId;
  final bool isFollowing;

  FollowerListScreen({required this.userId, required this.isFollowing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isFollowing ? 'Folgt' : 'Follower'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(isFollowing ? 'following' : 'followers')
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: Lottie.asset('assets/animations/loading.json'));
          }
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(isFollowing ? 'Folgt niemanden.' : 'Noch keine Follower.'),
            );
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              String userId = docs[index].id;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return ListTile(title: Text('Lädt...'));
                  }
                  var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userData?['photoUrl'] != null && userData?['photoUrl'].isNotEmpty
                          ? NetworkImage(userData!['photoUrl'])
                          : AssetImage('assets/icons/default_avatar.png') as ImageProvider,
                    ),
                    title: Text(userData?['name'] ?? 'Unbekannter Nutzer'),
                    onTap: () {
                      if(userId == FirebaseAuth.instance.currentUser!.uid) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MainScreen(
                              initialPage: 2,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileScreen(userId: userId),
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
