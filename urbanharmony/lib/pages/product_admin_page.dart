import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:urbanharmony/components/my_image_post.dart';
import '../services/firestore/firestore_product.dart';
import '../services/firestore/firestore_category.dart';

class ProductAdminPage extends StatefulWidget {
  const ProductAdminPage({super.key});

  @override
  State<ProductAdminPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductAdminPage> {
  final FirestoreService firestoreService = FirestoreService();
  final FirestoreCategoryService categoryService = FirestoreCategoryService();
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController productLinkController = TextEditingController();
  String? selectedCategoryId;
  String? selectedDocID;
  File? _image;
  String? _imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'.tr));
          }
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            List<QueryDocumentSnapshot> productsList = snapshot.data!.docs;
            return ListView(
              children: productsList.map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                return FutureBuilder<String>(
                  future: firestoreService.getCategoryName(data['CategoryId'] ?? ''),
                  builder: (context, categorySnapshot) {
                    return Column(
                      children: [
                        ListTile(
                          title: Text(data['ProductName'] ?? ''),
                          subtitle: Text(
                              '${'category'.tr}${categorySnapshot.data ?? 'loading'.tr}\n'
                                  '${'brand'.tr}${data['Brand'] ?? ''}\n'
                                  '${'price'.tr} ${data['Price']?.toString() ?? '0.00'}\n'
                                  '${'Link'.tr}: ${data['ProductLink'] ?? 'No link provided'.tr}'
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                onPressed: () => _openProductDialog(doc.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () async {
                                  try {
                                    await firestoreService.deleteProduct(doc.id);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to delete product: $e'.tr)),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        MyImagePost(imageUrl: data['ImageUrl']),
                      ],
                    );
                  },
                );
              }).toList(),
            );
          }
          return Center(child: Text('No products available.'.tr));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openProductDialog(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openProductDialog([String? docID]) async {
    _clearFields();
    if (docID != null) {
      await _editProduct(docID);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(docID == null ? 'Add Product'.tr : 'Update Product'.tr),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(productNameController, 'Product Name'),
                _buildCategoryDropdown(),
                _buildTextField(brandController, 'Brand'),
                _buildTextField(priceController, 'Price', isNumeric: true),
                _buildTextField(descriptionController, 'Description'),
                _buildTextField(productLinkController, 'Product Link'),
                const SizedBox(height: 10),
                _buildImagePreview(),
                ElevatedButton(
                  onPressed: _getImage,
                  child: Text('Choose Image'.tr),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearFields();
              },
              child: Text('Cancel'.tr),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedCategoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a category'.tr)),
                  );
                  return;
                }
                await _saveProduct();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
              child: Text(docID == null ? 'Add'.tr : 'Update'.tr),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: categoryService.getActiveCategoriesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error loading categories'.tr);
          }

          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }

          List<DropdownMenuItem<String>> categoryItems = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(data['Name'] ?? ''),
            );
          }).toList();

          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Category'.tr,
              border: const OutlineInputBorder(),
            ),
            value: selectedCategoryId,
            items: categoryItems,
            onChanged: (value) {
              setState(() {
                selectedCategoryId = value;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label.tr, border: const OutlineInputBorder()),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      ),
    );
  }

  Widget _buildImagePreview() {
    return _image != null
        ? Image.file(_image!, height: 100)
        : _imageUrl != null
        ? Image.network(_imageUrl!, height: 100)
        : Container();
  }

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<String?> _uploadImage() async {
    if (_image == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('product_images')
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

  Future<void> _saveProduct() async {
    try {
      String? imageUrl = await _uploadImage() ?? _imageUrl;
      if (selectedDocID == null) {
        await firestoreService.addProduct(
          productNameController.text,
          selectedCategoryId!,
          brandController.text,
          double.tryParse(priceController.text) ?? 0.0,
          descriptionController.text,
          imageUrl ?? '',
          productLinkController.text,
        );
      } else {
        await firestoreService.updateProduct(
          selectedDocID!,
          productNameController.text,
          selectedCategoryId!,
          brandController.text,
          double.tryParse(priceController.text) ?? 0.0,
          descriptionController.text,
          imageUrl ?? '',
          productLinkController.text,
        );
      }
      _clearFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save product: $e'.tr)),
      );
    }
  }

  void _clearFields() {
    setState(() {
      productNameController.clear();
      brandController.clear();
      priceController.clear();
      descriptionController.clear();
      productLinkController.clear();
      selectedCategoryId = null;
      _image = null;
      _imageUrl = null;
      selectedDocID = null;
    });
  }

  Future<void> _editProduct(String docID) async {
    try {
      DocumentSnapshot doc = await firestoreService.getProductById(docID);
      final data = doc.data() as Map<String, dynamic>;
      productNameController.text = data['ProductName'] ?? '';
      selectedCategoryId = data['CategoryId'];
      brandController.text = data['Brand'] ?? '';
      priceController.text = data['Price']?.toString() ?? '';
      descriptionController.text = data['Description'] ?? '';
      productLinkController.text = data['ProductLink'] ?? '';
      _imageUrl = data['ImageUrl'];
      selectedDocID = docID;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load product: $e'.tr)),
      );
    }
  }

  @override
  void dispose() {
    productNameController.dispose();
    brandController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    productLinkController.dispose();
    super.dispose();
  }
}