
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:urbanharmony/services/auth/auth_service.dart';
import '../services/firestore/firestore_feedback.dart';

class FeedbackAdminPage extends StatefulWidget {
  const FeedbackAdminPage({super.key});

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackAdminPage> {
  final _auth = AuthService();
  final FirestoreFeedback _firestoreFeedback = FirestoreFeedback();
  final TextEditingController _replyController = TextEditingController();
  String? _selectedFeedbackId;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('feedback_management'.tr), // Sử dụng khóa dịch
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreFeedback.getFeedbackStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('something_wrong'.tr); // Sử dụng khóa dịch
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;
              bool isSelected = _selectedFeedbackId == document.id;

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(data['message']),
                      subtitle: Row(
                        children: [
                          Text('rating'.tr + ': '), // Sử dụng khóa dịch
                          ...List.generate(
                            data['rating'],
                                (index) => const Icon(Icons.star, size: 18, color: Colors.amber),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.reply),
                            onPressed: () {
                              setState(() {
                                _selectedFeedbackId = isSelected ? null : document.id;
                              });
                            },
                          ),
                          if (data['userId'] == _auth.getCurrentUID())
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _firestoreFeedback.deleteFeedback(document.id);
                              },
                            ),
                        ],
                      ),
                    ),

                    if (isSelected) ...[
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestoreFeedback.getRepliesStream(document.id),
                        builder: (context, repliesSnapshot) {
                          if (!repliesSnapshot.hasData) {
                            return const SizedBox();
                          }

                          return Column(
                            children: repliesSnapshot.data!.docs.map((reply) {
                              Map<String, dynamic> replyData = reply.data() as Map<String, dynamic>;
                              return Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: ListTile(
                                  title: Text(replyData['message']),
                                  subtitle: Text('reply_from'.tr + ': ${replyData['userId']}'), // Sử dụng khóa dịch
                                  trailing: replyData['userId'] == _auth.getCurrentUID()
                                      ? IconButton(
                                    icon: const Icon(Icons.delete),
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

                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _replyController,
                                decoration: InputDecoration(
                                  hintText: 'write_reply'.tr, // Sử dụng khóa dịch
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
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
    );
  }
}