
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:urbanharmony/services/firestore/firestore_designer.dart';
import 'package:urbanharmony/services/firestore/firestore_product.dart';
import 'package:urbanharmony/services/firestore/firestore_review.dart';
import 'package:urbanharmony/services/firestore/firestore_user.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({Key? key}) : super(key: key);

  @override
  _ReviewsPageState createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final FirestoreReviewService reviewService = FirestoreReviewService();
  final FirestoreUserService userService = FirestoreUserService();
  final FirestoreService productService = FirestoreService();
  final FirestoreDesignerService designerService = FirestoreDesignerService();

  final TextEditingController commentController = TextEditingController();
  String? selectedDocID;
  String? selectedUserID;
  String? selectedProductID;
  String? selectedDesignerID;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('reviews'.tr), // Dịch "Đánh giá"
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: reviewService.getReviewsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'.tr));
          }
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            List<QueryDocumentSnapshot> reviewsList = snapshot.data!.docs;
            return ListView(
              children: reviewsList.map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  title: FutureBuilder<DocumentSnapshot>(
                    future: productService.getProductById(data['ProductID']),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return  Text('loading'.tr); // Dịch "Đang tải..."
                      final productData = snapshot.data?.data() as Map<String, dynamic>?;
                      return Text(productData?['ProductName'] ?? 'Unknown Product');
                    },
                  ),
                  subtitle: FutureBuilder<DocumentSnapshot>(
                    future: designerService.getDesignerById(data['DesignerID']),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Text('loading'.tr); // Dịch "Đang tải..."
                      final designerData = snapshot.data?.data() as Map<String, dynamic>?;
                      return Text(
                          'designer: ${designerData?['FullName'] ?? 'Unknown'}\ncomment: ${data['Comment'] ?? ''}'); // Dịch "nhà thiết kế" và "bình luận"
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueGrey),
                        onPressed: () => _openReviewDialog(doc.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          try {
                            await reviewService.deleteReview(doc.id);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('failed_to_delete_review'.tr + '$e')), // Dịch "Không thể xóa đánh giá: "
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }
          return  Center(child: Text('no_reviews_available'.tr)); // Dịch "Không có đánh giá nào."
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openReviewDialog(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openReviewDialog([String? docID]) async {
    _clearFields();
    if (docID != null) {
      await _editReview(docID);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(docID == null ? 'add_review'.tr : 'update_review'.tr), // Dịch "Thêm đánh giá" hoặc "Cập nhật đánh giá"
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDropdown(userService.getUsersStream(), selectedUserID, 'user'.tr, (newValue) {
                  setState(() { selectedUserID = newValue; });
                }),
                _buildDropdown(productService.getProductsStream(), selectedProductID, 'product'.tr, (newValue) {
                  setState(() { selectedProductID = newValue; });
                }),
                _buildDropdown(designerService.getDesignersStream(), selectedDesignerID, 'designer'.tr, (newValue) {
                  setState(() { selectedDesignerID = newValue; });
                }),
                _buildTextField(commentController, 'comment'.tr), // Dịch "Bình luận"
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearFields();
              },
              child:  Text('cancel'.tr), // Dịch "Hủy"
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveReview();
                Navigator.of(context).pop();
              },
              child: Text(docID == null ? 'add'.tr : 'update'.tr), // Dịch "Thêm" hoặc "Cập nhật"
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdown(Stream<QuerySnapshot> stream, String? selectedValue, String label, ValueChanged<String?> onChanged) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        return DropdownButtonFormField<String>(
          value: selectedValue,
          onChanged: onChanged,
          items: snapshot.data!.docs.map((doc) {
            return DropdownMenuItem(
              value: doc.id,
              child: Text(doc['Username'] ?? doc['ProductName'] ?? doc['FullName']),
            );
          }).toList(),
          decoration: InputDecoration(labelText: label),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
      ),
    );
  }

  Future<void> _saveReview() async {
    try {
      if (selectedDocID == null) {
        await reviewService.addReview(
          selectedUserID!,
          selectedProductID!,
          selectedDesignerID!,
          commentController.text,
        );
      } else {
        await reviewService.updateReview(
          selectedDocID!,
          commentController.text,
        );
      }
      _clearFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('failed_to_save_review'.tr + '$e')), // Dịch "Không thể lưu đánh giá: "
      );
    }
  }

  void _clearFields() {
    setState(() {
      commentController.clear();
      selectedUserID = null;
      selectedProductID = null;
      selectedDesignerID = null;
      selectedDocID = null;
    });
  }

  Future<void> _editReview(String docID) async {
    try {
      DocumentSnapshot doc = await reviewService.getReviewById(docID);
      final data = doc.data() as Map<String, dynamic>;
      commentController.text = data['Comment'] ?? '';
      selectedUserID = data['UserID'];
      selectedProductID = data['ProductID'];
      selectedDesignerID = data['DesignerID'];
      selectedDocID = docID;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('failed_to_load_review'.tr + '$e')), // Dịch "Không thể tải đánh giá: "
      );
    }
  }
}