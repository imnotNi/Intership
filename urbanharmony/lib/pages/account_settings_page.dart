
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:urbanharmony/services/auth/auth_service.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  void confirmDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("delete_account".tr), // Dịch tiêu đề xóa tài khoản
        content: Text("confirm_delete".tr), // Dịch nội dung xác nhận
        actions: [
          //cancel
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("cancel".tr), // Dịch nút hủy
          ),
          //delete
          TextButton(
            onPressed: () async {
              await AuthService().deleteAccount();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                    (route) => false,
              );
            },
            child: Text("delete".tr), // Dịch nút xóa
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("account_settings".tr), // Dịch tiêu đề cài đặt tài khoản
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: () => confirmDeletion(context),
            child: Container(
              padding: const EdgeInsets.all(25),
              margin: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  "delete_account_button".tr, // Dịch nút xóa tài khoản
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

