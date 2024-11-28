import 'package:flutter/material.dart';

class FullScreenImage extends StatelessWidget {
  // final String imageUrl;
  // final Function onDelete;
  // final Function onLike;
  final String imageUrl;
  final Function onDelete;
  final String receiverID;
  final dynamic chatService; // Thay thế bằng kiểu thực tế của chatService


  // FullScreenImage({required this.imageUrl, required this.onDelete, required this.onLike});
  const FullScreenImage({
    Key? key,
    required this.imageUrl,
    required this.onDelete,
    required this.receiverID,
    this.chatService,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image View'),

      ),
      // body: Center(
      //   child: Hero(
      //     tag: imageUrl,
      //     child: Image.network(imageUrl, fit: BoxFit.cover),
      //   ),
      // ),
      body: Center(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Text('Failed to load image'));
          },
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: Icon(Icons.favorite),
      //   onPressed: () {
      //     onLike();
      //     // Logic để thả cảm xúc có thể được thêm vào đây
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(content: Text('Image liked!')),
      //     );
      //   },
      // ),
    );
  }
}
