import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:urbanharmony/components/chat_bubble.dart';
import 'package:urbanharmony/components/my_textfield.dart';
import 'package:urbanharmony/services/auth/auth_service.dart';
import 'package:urbanharmony/services/chat/chat_service.dart';
import 'dart:io';
import 'full_screen_image.dart';

class ChatPage1 extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;

  ChatPage1({
    super.key,
    required this.receiverEmail,
    required this.receiverID,
  });

  @override
  State<ChatPage1> createState() => _ChatPage1State();
}

class _ChatPage1State extends State<ChatPage1> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  FocusNode myFocusNode = FocusNode();

  List<String> emojis = [
    '😀', '😁', '😂', '🤣', '😃', '😄', '😅', '😆', '😉', '😊',
    '😋', '😎', '😍', '😘', '😗', '😙', '😚', '🙂', '🤗', '🤩',
    '🤔', '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '😳', '😵',
    '😡', '😠', '😤', '😣', '😖', '😫', '😩', '😢', '😥', '😰',
    '😱', '😨', '😧', '😦', '😮', '😯', '😲', '😳', '🥺', '😵‍💫',
    '😷', '🤒', '🤕', '🤢', '🤮', '🤧', '😇', '🥳', '🥴', '😈',
    '👿', '💀', '☠️', '👻', '👽', '💩', '🤖', '🎃', '😺', '😸',
    '🌞', '🌜', '🌟', '🌈', '🌹', '🌻', '🌼', '🍀', '🍎', '🍉',
    '🍕', '🍔', '🍟', '🌭', '🍣', '🍰', '🍦', '🍩', '🍪', '🍫',
    '🍷', '🍺', '🍸', '🍹', '☕', '🥤', '🍵', '🌭', '🌮', '🍤',
    '🍙', '🍚', '🍘', '🍥', '🍣', '🥟', '🥢', '🍱', '🍛', '🍜',
  ];

  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 500), scrollDown);
      }
    });
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  final ScrollController _scrollController = ScrollController();

  void scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(widget.receiverID, _messageController.text);
      _messageController.clear();
      scrollDown();
    }
  }

  Future<String?> _uploadImage() async {
    if (_image == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child('${DateTime.now().toIso8601String()}.jpg');
      await ref.putFile(_image!);
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    }
  }

  Future<void> _getImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      String? imageUrl = await _uploadImage();
      if (imageUrl != null) {
        await _chatService.sendMessage(widget.receiverID, imageUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image uploaded successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed')),
        );
      }
    }
  }

  void _showEmojiPickerDialog() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  void _addEmoji(String emoji) {
    setState(() {
      _messageController.text += emoji;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.receiverEmail),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            if (_showEmojiPicker) _buildEmojiPicker(),
            _buildUserInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    String senderID = _authService.getCurrentUser()!.uid;
    return StreamBuilder(
      stream: _chatService.getMessages(widget.receiverID, senderID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error loading messages"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        return ListView(
          controller: _scrollController,
          children: snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isCurrentUser = data['senderID'] == _authService.getCurrentUser()!.uid;

    return Container(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ChatBubble(
        message: data["message"] ?? '', // Đảm bảo không có null
        isCurrentUser: isCurrentUser,
        onDelete: () async {
          await _chatService.deleteMessage(doc.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Message deleted successfully')),
          );
        },
        onLike: (emoji) {
          // Logic để xử lý khi thả cảm xúc
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You liked with: $emoji')),
          );
        },
        emoji: data["emoji"] ?? '', // Đảm bảo không có null
      ),
    );
  }

  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.image),
            onPressed: _getImage,
            color: Colors.blueAccent,
          ),
          IconButton(
            icon: Icon(Icons.emoji_emotions),
            onPressed: _showEmojiPickerDialog,
            color: Colors.blueAccent,
          ),
          Expanded(
            child: MyTextField(
              controller: _messageController,
              hintText: 'Type a message',
              obscureText: false,
              focusNode: myFocusNode,
            ),
          ),
          IconButton(
            onPressed: sendMessage,
            icon: const Icon(Icons.send, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return Container(
      height: 250,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.0,
        ),
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _addEmoji(emojis[index]),
            child: Center(
              child: Text(
                emojis[index],
                style: TextStyle(fontSize: 24),
              ),
            ),
          );
        },
      ),
    );
  }
}