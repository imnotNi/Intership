
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:urbanharmony/components/my_bio_box.dart';
import 'package:urbanharmony/components/my_follow_button.dart';
import 'package:urbanharmony/components/my_input_alert_box.dart';
import 'package:urbanharmony/components/my_post_tile.dart';
import 'package:urbanharmony/components/my_profile_stats.dart';
import 'package:urbanharmony/helper/image_picker.dart';
import 'package:urbanharmony/models/user.dart';
import 'package:urbanharmony/pages/chat_page.dart';
import 'package:urbanharmony/pages/follow_list_page.dart';
import 'package:urbanharmony/services/auth/auth_service.dart';
import 'package:urbanharmony/services/database/database_provider.dart';
import 'package:urbanharmony/services/storage/storage_service.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  const ProfilePage({super.key, required this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  //providers
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider =
  Provider.of<DatabaseProvider>(context, listen: false);
  //users
  UserProfile? user;
  String currentUserId = AuthService().getCurrentUID();
  //text controller
  final bioTextController = TextEditingController();

  //loading
  bool _isLoading = true;
  //follow state
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();

    loadUser();
  }

  Future<void> loadUser() async {
    user = await databaseProvider.userProfile(widget.uid);

    //load follow for user
    await databaseProvider.loadUserFollowers(widget.uid);
    await databaseProvider.loadUserFollowing(widget.uid);

    //update follow state
    _isFollowing = databaseProvider.isFollowing(widget.uid);

    setState(() {
      _isLoading = false;
    });
  }

  void _showEditBioBox() {
    showDialog(
        context: context,
        builder: (context) => MyInputAlertBox(
            textController: bioTextController,
            hintText: "edit_bio".tr, // Dịch "Chỉnh sửa tiểu sử.."
            onPressed: saveBio,
            onPressedText: "save".tr)); // Dịch "Lưu"
  }

  Future<void> saveBio() async {
    setState(() {
      _isLoading = true;
    });

    await databaseProvider.updateBio(bioTextController.text);
    await loadUser();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> saveAvatar() async {
    setState(() {
      _isLoading = true;
    });

    String? imageUrl = await _uploadImage() ?? _imageUrl;
    if (imageUrl == null) {
      // Show an error message or handle the null case as needed
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text('Image upload failed.'.tr),
        ),
      );
      return; // Prevent further execution
    }
    print(imageUrl);
    await updateAvatar(imageUrl);
    await loadUser();

    setState(() {
      _isLoading = false;
    });
  }

  //toggle follow
  Future<void> toggleFollow() async {
    if (_isFollowing) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("unfollow".tr), // Dịch "Bỏ theo dõi"
          content: Text("unfollowing_message".tr), // Dịch "Bạn có muốn bỏ theo dõi người dùng này không?"
          actions: [
            //cancel
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("cancel".tr), // Dịch "Hủy"
            ),
            //yes
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await databaseProvider.unfollowUser(widget.uid);
              },
              child: Text("yes".tr), // Dịch "Có"
            ),
          ],
        ),
      );
    } else {
      await databaseProvider.followUser(widget.uid);
    }

    setState(() {
      _isFollowing = !_isFollowing;
    });
  }

  String? _imageUrl;
  File? _image;

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = File(pickedFile!.path);
      print(_image);
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
        SnackBar(content: Text('Failed to upload image: $e'.tr)),
      );
      return null;
    }
  }

  Future<void> updateAvatar(String imageUrl) async {
    await databaseProvider.updateAvatar(imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    //get user post
    final allUserPosts = listeningProvider.filterUserPosts(widget.uid);
    //get follow
    final followerCount = listeningProvider.getFollowerCount(widget.uid);
    final followingCount = listeningProvider.getFollowingCount(widget.uid);
    //listen to is following
    _isFollowing = listeningProvider.isFollowing(widget.uid);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(_isLoading ? '' : user!.name),
            foregroundColor: Theme.of(context).colorScheme.primary,
            actions: [
              _isLoading ? const CircularProgressIndicator() : Visibility(
                visible: user!.uid != AuthService().getCurrentUID(),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage1(
                          receiverEmail: user!.email,
                          receiverID: user!.uid,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.messenger_rounded),
                ),
              ),
            ],
          ),
          body: ListView(
            children: [
              //username
              Center(
                child: Text(
                  _isLoading ? '' : '@${user!.username}',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 10),
              //profile picture
              Center(
                child: _isLoading ? const CircularProgressIndicator() :  Stack(
                  children: [
                    user!.imageUrl != ""
                        ? CircleAvatar(
                      radius: 64,
                      backgroundImage: NetworkImage(user!.imageUrl),
                    )
                        : const CircleAvatar(
                      radius: 65,
                      backgroundImage: AssetImage('assets/profile.png'),
                    ),
                    if (user != null && user!.uid == currentUserId)
                      Positioned(
                        bottom: -10,
                        left: 80,
                        child: IconButton(
                          onPressed: () async {
                            await _getImage();
                            if (user!.imageUrl != "")
                            {
                              StorageService().deleteImages(user!.imageUrl);
                            }
                            await saveAvatar();
                          },
                          icon: Icon(Icons.add_a_photo,
                              color: Theme.of(context).colorScheme.inversePrimary),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              MyProfileStats(
                postCount: allUserPosts.length,
                followerCount: followerCount,
                followingCount: followingCount,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FollowListPage(
                      uid: widget.uid,
                    ),
                  ),
                ),
              ),
              //follow
              const SizedBox(height: 25),
              if (user != null && user!.uid != currentUserId)
                MyFollowButton(
                  onPressed: toggleFollow,
                  isFollowing: _isFollowing,
                ),
              //edit bio
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "bio".tr, // Dịch "Tiểu sử"
                      style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                    //show edit if current user
                    if (user != null && user!.uid == currentUserId)
                      GestureDetector(
                        onTap: _showEditBioBox,
                        child: Icon(
                          Icons.settings,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              //bio
              MyBioBox(text: _isLoading ? '...' : user!.bio),

              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 25),
                child: Text(
                  "designs".tr, // Dịch "Thiết kế"
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),

              //user posts
              allUserPosts.isEmpty
                  ?  Center(
                child: Text("no_posts".tr), // Dịch "Không có bài viết.."
              )
                  : ListView.builder(
                itemCount: allUserPosts.length,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final post = allUserPosts[index];
                  return MyPostTile(
                    userImage: post.imageUrl,
                    post: post,
                    onUserTap: () {},
                  );
                },
              ),
            ],
          ),
        ),
        if (_isLoading)
          const Opacity(
            opacity: 1,
            child: ModalBarrier(dismissible: false, color: Colors.white),
          ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}