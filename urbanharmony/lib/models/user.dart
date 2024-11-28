import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String email;
  final String uid;
  // final String photoUrl;
  final String username;
  final String name;
  final String bio;
  final String role;
  final String imageUrl;
  final Timestamp timestamp;
  // final List followers;
  // final List following;

  UserProfile({
    required this.email,
    required this.uid,
    // required this.photoUrl,
    required this.username,
    required this.name,
    required this.bio,
    required this.role,
    required this.imageUrl,
    Timestamp? timestamp,

    // required this.followers,
    // required this.following,
  }): timestamp = timestamp ?? Timestamp.now();

  factory UserProfile.fromDocument(DocumentSnapshot doc) {
    return UserProfile(
      email: doc['email'],
      uid: doc['uid'],
      //   photoUrl: doc['photoUrl'],
      username: doc['username'],
      name: doc['name'],
      bio: doc['bio'],
      role: '',
      imageUrl: doc['imageUrl'],
      timestamp: doc['timestamp'] as Timestamp? ?? Timestamp.now(),
      //  followers: doc['followers'],
      // following: doc['following']
    );
  }
  Map<String, dynamic> toMap() => {
        "name": name,
        "uid": uid,
        "email": email,
        "username": username,
        "bio": bio,
        "role": role,
        "imageUrl" : imageUrl,
    "timestamp": timestamp,
        //  "followers": followers,
        //  "following": following,
        // 'photoUrl': photoUrl,
      };
}
