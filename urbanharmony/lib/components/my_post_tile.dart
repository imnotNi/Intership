import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urbanharmony/components/my_input_alert_box.dart';
import 'package:urbanharmony/helper/time_formatter.dart';
import 'package:urbanharmony/models/post.dart';
import 'package:urbanharmony/services/auth/auth_service.dart';
import 'package:urbanharmony/services/database/database_provider.dart';

class MyPostTile extends StatefulWidget {
  final String userImage;
  final Post post;
  final void Function()? onUserTap;
  final void Function()? onPostTap;
  const MyPostTile(
      {super.key,
      required this.post,
      required this.onUserTap,
      this.onPostTap,
      required this.userImage});

  @override
  State<MyPostTile> createState() => _MyPostTileState();
}

class _MyPostTileState extends State<MyPostTile> {
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider =
      Provider.of<DatabaseProvider>(context, listen: false);

  //on start up
  @override
  void initState() {
    super.initState();

    _loadComments();
  }

  //like
  void _toggleLikePost() async {
    try {
      await databaseProvider.toggleLike(widget.post.id);
    } catch (e) {
      print(e);
    }
  }

  //comment text controller
  final _commentController = TextEditingController();

  //comment
  void _openNewCommentBox() {
    showDialog(
      context: context,
      builder: (context) => MyInputAlertBox(
        textController: _commentController,
        hintText: "Type your comment",
        onPressed: () async {
          await _addComment();
        },
        onPressedText: "Post",
      ),
    );
  }

  //add comment
  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await databaseProvider.addComment(
          widget.post.id, _commentController.text.trim());
    } catch (e) {
      print(e);
    }
  }

  //load comment
  Future<void> _loadComments() async {
    await databaseProvider.loadComments(widget.post.id);
  }

  //more option (delete, report, block
  void _showOptions() {
    //check if owned post
    String currentUid = AuthService().getCurrentUID();
    final bool isOwnPost = widget.post.uid == currentUid;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (isOwnPost)
                //delete
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text("Delete"),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await databaseProvider.deletePost(widget.post.id);
                    } catch (e) {
                      print("WRONGGGG $e");
                    }
                  },
                )
              else ...[
                //report
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text("Report"),
                  onTap: () {
                    Navigator.pop(context);

                    _reportPostConfirmationBox();
                  },
                ),
                //block
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text("Block"),
                  onTap: () {
                    Navigator.pop(context);
                    _blockUserConfirmationBox();
                  },
                ),
              ],

              //cancel
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text("Cancel"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  //report
  void _reportPostConfirmationBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Report Message"),
        content: Text("Do you want to report this post?"),
        actions: [
          //cancel
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          //report
          TextButton(
            onPressed: () async {
              await databaseProvider.reportUser(
                  widget.post.id, widget.post.uid);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reported successfully!")));
            },
            child: Text("Report"),
          ),
        ],
      ),
    );
  }

  //block
  void _blockUserConfirmationBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Block Message"),
        content: Text("Do you want to block this user?"),
        actions: [
          //cancel
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          //report
          TextButton(
            onPressed: () async {
              await databaseProvider.blockUser(widget.post.uid);

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Blocked successfully!")));
            },
            child: Text("Block"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //check if user like post
    bool likedByCurrentUser =
        listeningProvider.isPostLikedByCurrentUser(widget.post.id);
    //listen to like count
    int likeCount = listeningProvider.getLikeCount(widget.post.id);
    //listen to comment count
    int commentCount = listeningProvider.getComments(widget.post.id).length;

    return GestureDetector(
      onTap: widget.onPostTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: widget.onUserTap,
              child: Row(
                children: [
                  //profile
                  Icon(Icons.person,
                      color: Theme.of(context).colorScheme.primary),

                  const SizedBox(width: 10),
                  //name
                  Text(
                    widget.post.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '@${widget.post.username}',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),

                  const Spacer(),

                  GestureDetector(
                    onTap: _showOptions,
                    child: Icon(Icons.more_horiz,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            //message
            Text(
              widget.post.message,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary),
            ),
            const SizedBox(height: 20),
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                image: DecorationImage(
                  image: NetworkImage(widget.userImage),
                  fit: BoxFit.contain,
                ),

              ),
            ),

            const SizedBox(height: 20),
            //button
            Row(
              children: [
                //like
                SizedBox(
                  width: 60,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleLikePost,
                        child: likedByCurrentUser
                            ? const Icon(
                                Icons.favorite,
                                color: Colors.red,
                              )
                            : Icon(
                                Icons.favorite,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                      ),
                      //like count
                      Text(
                        likeCount.toString(),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                //comment
                Row(
                  children: [
                    GestureDetector(
                      onTap: _openNewCommentBox,
                      child: Icon(Icons.comment,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 5),
                    Text(commentCount != 0 ? commentCount.toString() : '',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
                const Spacer(),
                Text(formatTimestamp(widget.post.timestamp)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
