import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreReviewService {
  final CollectionReference reviews = FirebaseFirestore.instance.collection('Reviews');

  Future<void> addReview(String userID, String productID, String designerID, String comment) async {
    await reviews.add({
      'UserID': userID,
      'ProductID': productID,
      'DesignerID': designerID,
      'Comment': comment,
      'CreatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateReview(String docId, String comment) async {
    await reviews.doc(docId).update({
      'Comment': comment,
      'UpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReview(String docId) async {
    await reviews.doc(docId).delete();
  }

  Stream<QuerySnapshot> getReviewsStream() {
    return reviews.snapshots();
  }

  Future<DocumentSnapshot> getReviewById(String docId) async {
    return await reviews.doc(docId).get();
  }
}