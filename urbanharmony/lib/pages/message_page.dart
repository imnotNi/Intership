
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urbanharmony/pages/chat_page.dart';
import '../components/user_tile.dart';
import '../services/auth/auth_service.dart';
import '../services/chat/chat_service.dart';

class MessagePage extends StatelessWidget {
  MessagePage({super.key});

  final ChatService _chatService = ChatService();

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Center(child: _buildUserList()),
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error".tr));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Text("Loading..".tr));
        }

        final userList = snapshot.data ?? [];

        return ListView(
          children: userList.map<Widget>((userData) => _buildUserListItem(userData, context))
              .toList(),
        );
      },
    );
  }

  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    // Get email safely
    final email = userData["email"];
    // Check if email is not null and not the current user's email
    if (email != null && email != _authService.getCurrentUser()?.email) {
      return UserTile(
        text: email,
        onTap: () {
           Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage1(
                receiverEmail: userData["email"],
                receiverID: userData["uid"],
              ),
            ),
          );
        },
      );
    }

    // Return an empty container if the email is null or matches the current user's email
    return const SizedBox.shrink();
  }
}