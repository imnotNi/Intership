import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String uid;
  final String name;
  final String username;
  final String message;
  final Timestamp timestamp;
  final int likes;
  final List<String> likedBy;
  final String imageUrl;

  Post({
    required this.id,
    required this.uid,
    required this.name,
    required this.username,
    required this.message,
    required this.timestamp,
    required this.likes,
    required this.likedBy,
    required this.imageUrl,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      id: doc.id,
      uid: doc['uid'],
      name: doc['name'],
      username: doc['username'],
      message: doc['message'],
      timestamp: doc['timestamp'],
      likes: doc['likes'],
      likedBy: List<String>.from(doc['likedBy'] ?? []),
      imageUrl: doc['imageUrl'],
    );
  }
  Map<String, dynamic> toMap() => {
        "uid": uid,
        "name": name,
        "username": username,
        "message": message,
        "timestamp": timestamp,
        "likes": likes,
        "likedBy": likedBy,
        "imageUrl": imageUrl,
      };
}
