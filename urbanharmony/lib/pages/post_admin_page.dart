// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:urbanharmony/components/my_image_post.dart';
// import 'package:urbanharmony/components/my_post_tile.dart';
// import 'package:urbanharmony/helper/navigate_pages.dart';
// import 'package:urbanharmony/models/post.dart';
// import 'package:urbanharmony/services/database/database_provider.dart';
//
// import '../helper/time_formatter.dart';
//
// class PostAdminPage extends StatefulWidget {
//   const PostAdminPage({super.key});
//
//   @override
//   State<PostAdminPage> createState() => _PostAdminPageState();
// }
//
// class _PostAdminPageState extends State<PostAdminPage> {
//   late final listeningProvider = Provider.of<DatabaseProvider>(context);
//
//   late final databaseProvider =
//       Provider.of<DatabaseProvider>(context, listen: false);
//
//   @override
//   void initState() {
//     super.initState();
//
//     //load all post
//     loadAllPosts();}
//
//   Future<void> loadAllPosts() async {
//     await databaseProvider.loadAllPosts();
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Theme.of(context).colorScheme.surface,
//       appBar: AppBar(
//         title: const Text('Report Management'),
//         backgroundColor: Theme.of(context).colorScheme.primary,
//       ),
//       body:
//         _buildPostList(listeningProvider.reportPosts),
//     );
//   }
//
//
//   Widget _buildPostList(List<Post> posts) {
//     return posts.isEmpty
//         ? const Center(
//             child: Text("Nothing here"),
//           )
//         : ListView.builder(
//             itemCount: posts.length,
//             itemBuilder: (context, index) {
//               final post = posts[index];
//               return Column(
//                 children: [
//                   ListTile(
//                     title: Text('Name: ${post.name ?? ''}'),
//                     subtitle: Text('Username: ${post.username ?? ''}\nMessage: ${post.message?? ''}\nTimestamp: ${formatTimestamp(post.timestamp) ?? ''}'),
//                     trailing: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         IconButton(
//                           icon: const Icon(Icons.delete, color: Colors.redAccent),
//                           onPressed: () async {
//                             try {
//                               await databaseProvider.deletePost(post.id);
//                             } catch (e) {
//                               print("WRONGGGG $e");
//                             }
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                   MyImagePost(imageUrl: post.imageUrl),
//                 ],
//               );
//             },
//           );
//   }
// }
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:urbanharmony/components/my_image_post.dart';
import 'package:urbanharmony/components/my_post_tile.dart';
import 'package:urbanharmony/helper/navigate_pages.dart';
import 'package:urbanharmony/models/post.dart';
import 'package:urbanharmony/services/database/database_provider.dart';

import '../helper/time_formatter.dart';

class PostAdminPage extends StatefulWidget {
  const PostAdminPage({super.key});

  @override
  State<PostAdminPage> createState() => _PostAdminPageState();
}

class _PostAdminPageState extends State<PostAdminPage> {
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();
    //load all post
    loadAllPosts();
  }

  Future<void> loadAllPosts() async {
    await databaseProvider.loadAllPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('report_management'.tr), // Sử dụng khóa dịch
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _buildPostList(listeningProvider.reportPosts),
    );
  }

  Widget _buildPostList(List<Post> posts) {
    return posts.isEmpty
        ? Center(
      child: Text('nothing_here'.tr), // Sử dụng khóa dịch
    )
        : ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Column(
          children: [
            ListTile(
              title: Text('name'.tr + ': ${post.name ?? ''}'), // Sử dụng khóa dịch
              subtitle: Text('username'.tr + ': ${post.username ?? ''}\n'
                  'message'.tr + ': ${post.message ?? ''}\n'
                  'timestamp'.tr + ': ${formatTimestamp(post.timestamp) ?? ''}'), // Sử dụng khóa dịch
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      try {
                        await databaseProvider.deletePost(post.id);
                      } catch (e) {
                        print("WRONGGGG $e");
                      }
                    },
                  ),
                ],
              ),
            ),
            MyImagePost(imageUrl: post.imageUrl),
          ],
        );
      },
    );
  }
}