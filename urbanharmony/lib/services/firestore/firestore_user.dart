import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreUserService {
  final CollectionReference users = FirebaseFirestore.instance.collection('Users');

  Future<void> addUser(String username, String email, String password, String role) async {
    await users.add({
      'Username': username,
      'Email': email,
      'Password': password, // Note: In a real app, never store plain text passwords
      'Role': role,
    });
  }

  Future<void> updateUser(String docId, String username, String email, String role) async {
    await users.doc(docId).update({
      'Username': username,
      'Email': email,
      'Role': role,
    });
  }

  Future<void> deleteUser(String docId) async {
    await users.doc(docId).delete();
  }

  Stream<QuerySnapshot> getUsersStream() {
    return users.snapshots();
  }

  Future<DocumentSnapshot> getUserById(String docId) async {
    return await users.doc(docId).get();
  }
}