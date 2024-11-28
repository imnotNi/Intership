import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../services/database/database_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UsersPage> {
  final DatabaseService _databaseService = DatabaseService();
  late Stream<QuerySnapshot> _usersStream;

  @override
  void initState() {
    super.initState();
    _usersStream = FirebaseFirestore.instance.collection('Users').snapshots();
  }

  Future<void> _showUpdateUserDialog(DocumentSnapshot userDoc) async {
    final data = userDoc.data() as Map<String, dynamic>;
    final TextEditingController nameController = TextEditingController(text: data['name']);
    final TextEditingController emailController = TextEditingController(text: data['email']);
    final TextEditingController bioController = TextEditingController(text: data['bio'] ?? '');
    final TextEditingController passwordController = TextEditingController();

    // Ensure selectedRole is non-null String
    String selectedRole = (data['role'] as String?) ?? 'User';
    // Validate role value
    if (selectedRole != 'User' && selectedRole != 'Admin') {
      selectedRole = 'User';
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('update_user'.tr),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: 'name'.tr),
                      ),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(labelText: 'email'.tr),
                      ),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: InputDecoration(labelText: 'role'.tr),
                        items: const [
                          DropdownMenuItem(
                            value: 'User',
                            child: Text('User'),
                          ),
                          DropdownMenuItem(
                            value: 'Admin',
                            child: Text('Admin'),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedRole = newValue;
                            });
                          }
                        },
                      ),
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                            labelText: 'password'.tr,
                            hintText: 'hint_password'.tr
                        ),
                        obscureText: true,
                      ),
                      TextField(
                        controller: bioController,
                        decoration: InputDecoration(labelText: 'bio'.tr),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('cancel'.tr),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                        String uid = userDoc.id;

                        // Update role if changed
                        if (data['role'] != selectedRole) {
                          await _databaseService.updateUserRole(uid, selectedRole);
                        }

                        // Update other fields
                        Map<String, dynamic> updateData = {
                          'name': nameController.text,
                          'email': emailController.text,
                          'bio': bioController.text,
                          'role': selectedRole,
                        };

                        await userDoc.reference.update(updateData);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('user_updated_successfully'.tr),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('validation_error'.tr),
                              content: Text('name_email_required'.tr),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    child: Text('update'.tr),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  Future<void> _deleteUser(DocumentSnapshot userDoc) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm_delete'.tr), // Sử dụng khóa dịch
        content: Text('delete_user_confirmation'.tr), // Sử dụng khóa dịch
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr), // Sử dụng khóa dịch
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('delete'.tr, style: TextStyle(color: Colors.red)), // Sử dụng khóa dịch
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await _databaseService.deleteUserInfoFromFirebase(userDoc.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('user_deleted_successfully'.tr), // Sử dụng khóa dịch
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_to_delete_user'.tr), // Sử dụng khóa dịch
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _usersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('error ${snapshot.error}')); // Sử dụng khóa dịch
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return  Center(child: Text('no_users_found'.tr)); // Sử dụng khóa dịch
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot userDoc = snapshot.data!.docs[index];
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(userData['name'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userData['email'] ?? ''),
                    Text('Role: ${userData['role'] ?? "No role assigned"}',
                        style: const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showUpdateUserDialog(userDoc),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteUser(userDoc),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
