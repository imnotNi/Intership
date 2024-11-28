import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreCategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _categoriesCollection =>
      _db.collection('Categories');

  // Add a new category
  Future<void> addCategory(String name, String description, bool isActive) async {
    try {
      await _categoriesCollection.add({
        'Name': name,
        'Description': description,
        'IsActive': isActive,
        'CreatedAt': FieldValue.serverTimestamp(),
        'UpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  // Update an existing category
  Future<void> updateCategory(String docID, String name, String description, bool isActive) async {
    try {
      await _categoriesCollection.doc(docID).update({
        'Name': name,
        'Description': description,
        'IsActive': isActive,
        'UpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // Delete a category
  Future<void> deleteCategory(String docID) async {
    try {
      await _categoriesCollection.doc(docID).delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // Get a stream of all categories
  Stream<QuerySnapshot> getCategoriesStream() {
    return _categoriesCollection.snapshots();
  }

  // Get a single category by ID
  Future<DocumentSnapshot> getCategoryById(String docID) {
    return _categoriesCollection.doc(docID).get();
  }

  // Get active categories
  Stream<QuerySnapshot> getActiveCategoriesStream() {
    return _categoriesCollection.where('IsActive', isEqualTo: true).snapshots();
  }
}