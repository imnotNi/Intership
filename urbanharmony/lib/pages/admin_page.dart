import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:urbanharmony/components/navigation_bar.dart';
import 'package:urbanharmony/pages/backgroundadmin_page.dart';
import 'package:urbanharmony/pages/gallery_page.dart';
import 'package:urbanharmony/pages/post_admin_page.dart';
import 'package:urbanharmony/pages/product_admin_page.dart';
import 'package:urbanharmony/pages/products_page.dart';
import 'package:urbanharmony/pages/user_page.dart';
import '../services/firestore/firestore.dart';
import 'category_page.dart';
import 'dashboard_feedback_page.dart';
import 'dashboard_user_page.dart';
import 'feedbackadmin_page.dart';
import 'products_dashboard.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<AdminHomePage> {
  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController textController = TextEditingController();
  int _currentIndex = 0;

  void openNoteBox({String? docID}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.grey[200],
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (docID == null) {
                firestoreService.addNote(textController.text);
              } else {
                firestoreService.updateNote(docID, textController.text);
              }
              textController.clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(docID == null ? "Add" : "Update"),
          ),
        ],
      ),
    );
  }

  Widget _buildScreen() {
    switch (_currentIndex) {
      case 0:
        return const ProductsDashboardPage();
      case 1:
        return const AdvancedDashboardPage();
      case 2:
        return const DashboardUserPage();
      case 3:
        return const CategoryPage();
      case 4:
        return const PostAdminPage();
      case 5:
        return const BackgroundAdminPage();
      default:
        return _buildNotesScreen();
    }
  }

  Widget _buildNotesScreen() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getNotesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<QueryDocumentSnapshot> notesList = snapshot.data!.docs;
          return ListView.builder(
            itemCount: notesList.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = notesList[index];
              String docID = document.id;
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              String noteText = data['note'] ?? '';
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(
                    noteText,
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => openNoteBox(docID: docID),
                        icon: const Icon(Icons.edit, color: Colors.blue),
                      ),
                      IconButton(
                        onPressed: () async {
                          try {
                            await firestoreService.deleteNote(docID);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete note: $e'.tr),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        return Center(
          child: Text(
            "No notes available.".tr,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade200, Colors.white],
          ),
        ),
        child: SafeArea(
          child: _buildScreen(),
        ),
      ),
      bottomNavigationBar: NavigationBarWidget(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
