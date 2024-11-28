import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../pages/full_screen_image.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final Function? onDelete; // Callback để xóa
  final Function(String)? onLike; // Callback để thả cảm xúc
  final String? emoji; // Thêm thuộc tính emoji để hiển thị cảm xúc

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onDelete,
    this.onLike,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return _buildContent(message, context);
  }

  Widget _buildContent(String message, BuildContext context) {
    if (message.startsWith('http') &&
        message.contains(RegExp(r'\.(jpg|png|gif)', caseSensitive: false))) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImage(
                    imageUrl: message,
                    onDelete: () {
                      if (onDelete != null) {
                        onDelete!();
                      }
                      Navigator.pop(context);
                    },
                    receiverID: '', // Replace with actual receiver ID
                    chatService:
                    null, // Replace with actual chatService if needed
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.only(top: 10),
              child: Image.network(
                message,
                width: 200,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Text('Failed to load image'.tr));
                },
              ),
            ),
          ),
          Positioned(
            bottom: 0, // Position at the bottom
            right: 0,   // Position at the right
            child: _buildEmojiPicker(context),
          ),
        ],
      );
    } else {
      return Stack(
        children: [
          Column(
            crossAxisAlignment: isCurrentUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isCurrentUser ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: _buildEmojiPicker(context),
          ),
        ],
      );
    }
  }

  Widget _buildEmojiPicker(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            _showEmojiDialog(context);
          },
          child: Icon(Icons.sentiment_satisfied_alt),
        ),
        if (emoji != null)
          Text(
            emoji!,
            style: TextStyle(fontSize: 24),
          ),
      ],
    );
  }

  void _showEmojiDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn cảm xúc'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _emojiButton(context, '😀'),
                _emojiButton(context, '😂'),
                _emojiButton(context, '😍'),
                _emojiButton(context, '😢'),
                _emojiButton(context, '😡'),
                _emojiButton(context, '🥳'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emojiButton(BuildContext context, String emoji) {
    return IconButton(
      icon: Text(emoji, style: TextStyle(fontSize: 36)),
      onPressed: () {
        if (onLike != null) {
          onLike!(emoji);
        }
        Navigator.of(context).pop();
      },
    );
  }
}
