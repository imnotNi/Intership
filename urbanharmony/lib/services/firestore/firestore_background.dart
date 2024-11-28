import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreBackground {
  final CollectionReference background = FirebaseFirestore.instance.collection('Backgrounds');

  Future<void> addBackground(String userID, String bgUrl) async {
    await background.add({
      'UserID': userID,
      'Url': bgUrl,
    });
  }

  Future<void> deleteBackground(String docId) async {
    await background.doc(docId).delete();
  }

  Stream<QuerySnapshot> getBackgroundsStream() {
    return background.snapshots();
  }

  Future<QuerySnapshot> getBackgroundByUserId(String userID) async {
    return await background.where('UserID', isEqualTo: userID).get();
  }

}