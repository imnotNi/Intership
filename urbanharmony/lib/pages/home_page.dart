import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:urbanharmony/components/my_input_image_alert_box.dart';
import 'package:urbanharmony/components/my_post_tile.dart';
import 'package:urbanharmony/helper/navigate_pages.dart';
import 'package:urbanharmony/models/post.dart';
import 'package:urbanharmony/services/database/database_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //provider
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider =
  Provider.of<DatabaseProvider>(context, listen: false);
  File? _image;
  String? _imageUrl;
  //text controller
  final _messageController = TextEditingController();

  //on startup
  @override
  void initState() {
    super.initState();
    //load all post
    loadAllPosts();
  }

  Future<void> loadAllPosts() async {
    await databaseProvider.loadAllPosts();
  }

  void _openPostMessageBox() {
    showDialog(
      context: context,
      builder: (context) => MyInputImageAlertBox(
        textController: _messageController,
        hintText: 'show_your_design'.tr, // Dịch gợi ý
        mywidget: _buildImagePreview(),
        onTap: _getImage,
        onCancel: _clearFields,
        onPressed: () async {
          String? imageUrl = await _uploadImage() ?? _imageUrl;
          if (imageUrl == null) {
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                content: Text('image_upload_failed'.tr), // Dịch thông báo lỗi
              ),
            );
            return; // Ngăn chặn thực thi tiếp theo
          }
          await postMessage(_messageController.text, imageUrl);
        },
        onPressedText: 'post'.tr, // Dịch nút đăng
      ),
    );
  }

  Future<void> postMessage(String message, String imageUrl) async {
    await databaseProvider.postMessage(message, imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.secondary,
          title: TabBar(
            dividerColor: Colors.transparent,
            labelColor: Theme.of(context).colorScheme.inversePrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.primary,
            indicatorColor: Theme.of(context).colorScheme.inversePrimary,
            tabs: [
              Tab(text: 'for_you'.tr), // Dịch tab "Dành cho bạn"
              Tab(text: 'following'.tr), // Dịch tab "Đang theo dõi"
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openPostMessageBox,
          child: const Icon(Icons.add),
        ),
        body: TabBarView(children: [
          _buildPostList(listeningProvider.allPosts),
          _buildPostList(listeningProvider.followingPosts),
        ]),
      ),
    );
  }

  void _clearFields() {
    setState(() {
      Navigator.pop(context);
      _messageController.clear();
      _image = null;
      _imageUrl = null;
    });
  }

  Widget _buildPostList(List<Post> posts) {
    return posts.isEmpty
        ?  Center(
      child: Text('nothing_here'.tr), // Dịch thông báo không có gì ở đây
    )
        : ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return MyPostTile(
          userImage: post.imageUrl,
          post: post,
          onUserTap: () => goUserPage(context, post.uid),
          onPostTap: () => goPostPage(context, post),
        );
      },
    );
  }

  Widget _buildImagePreview() {
    return _image != null
        ? Image.file(_image!, height: 100)
        : _imageUrl != null
        ? Image.network(_imageUrl!, height: 100)
        : Container();
  }

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = File(pickedFile!.path);
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('image_picked'.tr)), // Dịch thông báo hình ảnh đã chọn
      );
    });
  }

  Future<String?> _uploadImage() async {
    if (_image == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('upload_images')
          .child('${DateTime.now().toIso8601String()}.jpg');
      await ref.putFile(_image!);
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('failed_to_upload_image'.tr + '$e')), // Dịch thông báo lỗi tải hình ảnh
      );
      return null;
    }
  }
}
