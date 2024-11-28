import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:urbanharmony/models/comment.dart';
import 'package:urbanharmony/services/auth/auth_service.dart';
import 'package:urbanharmony/services/database/database_provider.dart';

class MyCommentTile extends StatelessWidget {
  final Comment comment;
  final void Function()? onUserTap;
  const MyCommentTile({super.key, required this.comment,required this.onUserTap});

  void _showOptions(BuildContext context) {
    //check if owned post
    String currentUid = AuthService().getCurrentUID();
    final bool isOwnComment = comment.uid == currentUid;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (isOwnComment)
              //delete
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text("Delete"),
                  onTap: () async {
                    Navigator.pop(context);
                    await Provider.of<DatabaseProvider>(context, listen: false).deleteComment(comment.id, comment.postId);
                  },
                )
              else ...[
                //report
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: const Text("Report"),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                //block
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text("Block"),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],

              //cancel
              ListTile(
                leading: const Icon(Icons.delete),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onUserTap,
            child: Row(
              children: [
                //profile
                Icon(Icons.person,
                    color: Theme.of(context).colorScheme.primary),

                const SizedBox(width: 10),
                //name
                Text(
                  comment.name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '@${comment.username}',
                  style:
                  TextStyle(color: Theme.of(context).colorScheme.primary),
                ),

                const Spacer(),

                GestureDetector(
                  onTap: () => _showOptions(context),
                  child: Icon(Icons.more_horiz,
                      color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          //message
          Text(
            comment.message,
            style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary),
          ),

        ],
      ),
    );
  }
}
