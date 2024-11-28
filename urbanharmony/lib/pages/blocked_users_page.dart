
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:urbanharmony/services/database/database_provider.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  //provider
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

  //on startup
  @override
  void initState() {
    super.initState();
    //load blocked users
    loadBlockedUsers();
  }

  Future<void> loadBlockedUsers() async {
    await databaseProvider.loadBlockedUsers();
  }

  //show unlock box
  void _showUnlockConfirmationBox(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("unlock".tr), // Dịch tiêu đề mở khóa
        content: Text("confirm_unlock".tr), // Dịch nội dung xác nhận
        actions: [
          //cancel
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("cancel".tr), // Dịch nút hủy
          ),
          //unblock
          TextButton(
            onPressed: () async {
              await databaseProvider.unblockUser(userId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("unblock_success".tr))); // Dịch thông báo mở khóa thành công
            },
            child: Text("unblock".tr), // Dịch nút mở khóa
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //listen to blocked user
    final blockedUsers = listeningProvider.blockedUsers;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text("blocked_users".tr), // Dịch tiêu đề người dùng bị chặn
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: blockedUsers.isEmpty
          ? Center(
        child: Text("no_blocked_users".tr), // Dịch thông báo không có người dùng bị chặn
      )
          : ListView.builder(
        itemCount: blockedUsers.length,
        itemBuilder: (context, index) {
          final user = blockedUsers[index];

          return ListTile(
            title: Text(user.name),
            subtitle: Text('@${user.username}'),
            trailing: IconButton(
              onPressed: () => _showUnlockConfirmationBox(user.uid),
              icon: const Icon(Icons.block),
            ),
          );
        },
      ),
    );
  }
}