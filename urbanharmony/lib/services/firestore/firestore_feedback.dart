import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreFeedback {
  final CollectionReference feedbackCollection = FirebaseFirestore.instance.collection('Feedback');

  // Add a new feedback
  Future<void> addFeedback(String userId, String message, int rating) {
    return feedbackCollection.add({
      'userId': userId,
      'message': message,
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all feedback
  Stream<QuerySnapshot> getFeedbackStream() {
    return feedbackCollection.orderBy('createdAt', descending: true).snapshots();
  }

  // Delete a feedback
  Future<void> deleteFeedback(String docId) {
    return feedbackCollection.doc(docId).delete();
  }

  // Update a feedback
  Future<void> updateFeedback(String docId, String message, int rating) {
    return feedbackCollection.doc(docId).update({
      'message': message,
      'rating': rating,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Add a new reply to a feedback
  Future<void> addReply(String feedbackId, String userId, String replyMessage) {
    return feedbackCollection.doc(feedbackId).collection('replies').add({
      'userId': userId,
      'message': replyMessage,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get replies for a specific feedback
  Stream<QuerySnapshot> getRepliesStream(String feedbackId) {
    return feedbackCollection
        .doc(feedbackId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // Delete a reply
  Future<void> deleteReply(String feedbackId, String replyId) {
    return feedbackCollection
        .doc(feedbackId)
        .collection('replies')
        .doc(replyId)
        .delete();
  }
}