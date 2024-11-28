import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:urbanharmony/services/auth/auth_service.dart';
import '../services/firestore/firestore_feedback.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _auth = AuthService();
  final FirestoreFeedback _firestoreFeedback = FirestoreFeedback();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  int _rating = 0;
  String? _selectedFeedbackId; // Để theo dõi feedback nào đang được mở

  @override
  void dispose() {
    _messageController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('Feedback'.tr),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          // Phần nhập feedback
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Feedback Message'.tr,
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
              );
            }),
          ),
          ElevatedButton(
            child: Text('Submit Feedback'.tr),
            onPressed: () {
              if (_messageController.text.isNotEmpty && _rating > 0) {
                _firestoreFeedback.addFeedback(
                  _auth.getCurrentUID(),
                  _messageController.text,
                  _rating,
                );
                _messageController.clear();
                setState(() {
                  _rating = 0;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Feedback submitted successfully'.tr)),
                );
              }
            },
          ),

          // Danh sách feedback
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreFeedback.getFeedbackStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Something went wrong'.tr);
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                return ListView(
                  children: snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                    bool isSelected = _selectedFeedbackId == document.id;

                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(data['message']),
                            subtitle: Row(
                              children: [
                                Text('Rating: '.tr),
                                ...List.generate(
                                  data['rating'],
                                      (index) => Icon(Icons.star, size: 18, color: Colors.amber),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.reply),
                                  onPressed: () {
                                    setState(() {
                                      // Toggle selected feedback
                                      _selectedFeedbackId = isSelected ? null : document.id;
                                    });
                                  },
                                ),
                                if (data['userId'] == _auth.getCurrentUID())
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () {
                                      _firestoreFeedback.deleteFeedback(document.id);
                                    },
                                  ),
                              ],
                            ),
                          ),

                          // Hiển thị phần reply chỉ khi feedback được chọn
                          if (isSelected) ...[
                            // Danh sách các reply
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestoreFeedback.getRepliesStream(document.id),
                              builder: (context, repliesSnapshot) {
                                if (!repliesSnapshot.hasData) {
                                  return SizedBox();
                                }

                                return Column(
                                  children: repliesSnapshot.data!.docs.map((reply) {
                                    Map<String, dynamic> replyData = reply.data() as Map<String, dynamic>;
                                    // return Padding(
                                    //   padding: EdgeInsets.only(left: 16.0),
                                    //   child: ListTile(
                                    //     title: Text(replyData['message']),
                                    //     subtitle: Text('Reply from: ${replyData['userId']}'),
                                    //     trailing: replyData['userId'] == _auth.getCurrentUID()
                                    //         ? IconButton(
                                    //       icon: Icon(Icons.delete),
                                    //       onPressed: () {
                                    //         _firestoreFeedback.deleteReply(document.id, reply.id);
                                    //       },
                                    //     )
                                    //         : null,
                                    //   ),
                                    // );
                                    return Padding(
                                      padding: EdgeInsets.only(left: 16.0),
                                      child: ListTile(
                                        title: Text(replyData['message']),
                                        subtitle: Text('reply_from'.tr + ': ${replyData['userId']}'), // Sử dụng khóa dịch
                                        trailing: replyData['userId'] == _auth.getCurrentUID()
                                            ? IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            _firestoreFeedback.deleteReply(document.id, reply.id);
                                          },
                                        )
                                            : null,
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),

                            // Phần nhập reply
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _replyController,
                                      decoration: InputDecoration(
                                        hintText: 'Write a reply...'.tr,
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.send),
                                    onPressed: () {
                                      if (_replyController.text.isNotEmpty) {
                                        _firestoreFeedback.addReply(
                                          document.id,
                                          _auth.getCurrentUID(),
                                          _replyController.text,
                                        );
                                        _replyController.clear();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}