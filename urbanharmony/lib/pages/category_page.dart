import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:urbanharmony/services/firestore/firestore_category.dart'; // Đảm bảo import đúng đường dẫn

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final FirestoreCategoryService categoryService = FirestoreCategoryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title:  Text('Categories Management'.tr),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: categoryService.getCategoriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'.tr));
          }
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            List<QueryDocumentSnapshot> categoriesList = snapshot.data!.docs;
            return _buildCategoryList(categoriesList);
          }
          return Center(child: Text('No categories available.'.tr));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(List<QueryDocumentSnapshot> categoriesList) {
    return ListView.builder(
      itemCount: categoriesList.length,
      itemBuilder: (context, index) {
        var category = categoriesList[index];
        Map<String, dynamic> data = category.data() as Map<String, dynamic>;
        return _buildCategoryCard(data, category.id);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> data, String docID) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(data['Name'.tr] ?? ''),
        subtitle: Text(data['Description'.tr] ?? ''),
        trailing: Icon(
          data['IsActive'.tr] == true ? Icons.check_circle : Icons.cancel,
          color: data['IsActive'.tr] == true ? Colors.green : Colors.red,
        ),
        onTap: () => _showCategoryDetails(data, docID),
      ),
    );
  }

  void _showCategoryDetails(Map<String, dynamic> data, String docID) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(data['Name'.tr] ?? ''),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Description: ${data['Description'] ?? ''}'),
                Text('Status: ${data['IsActive'] == true ? 'Active' : 'Inactive'}'),
                Text('Created At: ${data['CreatedAt']?.toDate().toString() ?? 'N/A'}'),
                Text('Updated At: ${data['UpdatedAt']?.toDate().toString() ?? 'N/A'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'.tr),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showEditCategoryDialog(data, docID);
              },
              child: Text('Edit'.tr),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCategory(docID);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child:  Text('Delete'.tr),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    String name = '';
    String description = '';
    bool isActive = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:  Text('Add New Category'.tr),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => name = value,
                  decoration:  InputDecoration(labelText: 'Name'.tr),
                ),
                TextField(
                  onChanged: (value) => description = value,
                  decoration:  InputDecoration(labelText: 'Description'.tr),
                ),
                CheckboxListTile(
                  title:  Text('Active'.tr),
                  value: isActive,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        isActive = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                categoryService.addCategory(name, description, isActive);
              },
              child:  Text('Add'.tr),
            ),
          ],
        );
      },
    );
  }

  void _showEditCategoryDialog(Map<String, dynamic> data, String docID) {
    String name = data['Name'] ?? '';
    String description = data['Description'] ?? '';
    bool isActive = data['IsActive'] ?? true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:  Text('Edit Category'.tr),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => name = value,
                  decoration: InputDecoration(labelText: 'Name'.tr),
                  controller: TextEditingController(text: name),
                ),
                TextField(
                  onChanged: (value) => description = value,
                  decoration:  InputDecoration(labelText: 'Description'.tr),
                  controller: TextEditingController(text: description),
                ),
                CheckboxListTile(
                  title:  Text('Active'.tr),
                  value: isActive,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        isActive = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child:  Text('Cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                categoryService.updateCategory(docID, name, description, isActive);
              },
              child:  Text('Update'.tr),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(String docID) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:  Text('Confirm Deletion'.tr),
          content: Text('Are you sure you want to delete this category?'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'.tr),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                categoryService.deleteCategory(docID);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Delete'.tr),
            ),
          ],
        );
      },
    );
  }
}