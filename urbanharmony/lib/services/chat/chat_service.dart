import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:urbanharmony/models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
// List<Map<String,dynamic> = [
// {
//   'email': test@gmail.com,
// 'id': ..
// },
// {
// 'email': mitch@gmail.com,
// 'id': ..
// },
// ]
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }
  // Future<void> sendMessage(String receiverID, message) async{
  //
  //   final String currentUserID = _auth.currentUser!.uid;
  //   final String currentUserEmail = _auth.currentUser!.email!;
  //   final Timestamp timestamp = Timestamp.now();
  //
  //   Message newMessage = Message(
  //       senderID: currentUserID,
  //       senderEmail: currentUserEmail,
  //       receiverID: receiverID,
  //       message: message,
  //       timestamp: timestamp);
  Future<void> sendMessage(String receiverID, String message, {String? emoji}) async {
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    Map<String, dynamic> newMessage = {
      'senderID': currentUserID,
      'senderEmail': currentUserEmail,
      'receiverID': receiverID,
      'message': message,
      'emoji': emoji ?? '', // Lưu emoji nếu có
      'timestamp': timestamp,
    };

    List<String> ids = [currentUserID, receiverID];
    ids.sort();

    String chatRoomID = ids.join('_');
    //co sua
    //   await _firestore
    //       .collection("Chat_rooms")
    //       .doc(chatRoomID)
    //       .collection("Messages")
    //       .add(newMessage.toMap());
    // }
    await _firestore
        .collection("Chat_rooms")
        .doc(chatRoomID)
        .collection("Messages")
        .add(newMessage);
  }
  Stream<QuerySnapshot> getMessages(String userID, otherUserID){
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');
    return _firestore
        .collection("Chat_rooms")
        .doc(chatRoomID)
        .collection("Messages")
        .orderBy("timestamp", descending: false)
        .snapshots();

  }

  sendImage(String receiverID, String path) {}

  deleteMessage(String id) {}
}

