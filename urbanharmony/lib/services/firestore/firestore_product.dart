import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _productsCollection => _db.collection('Products');
  CollectionReference get _categoriesCollection => _db.collection('Categories');

  // Add a new product
  Future<void> addProduct(String name, String categoryId, String brand, double price,
      String description, String imageUrl, String productLink) async {
    try {
      await _productsCollection.add({
        'ProductName': name,
        'categoryId': categoryId,
        'Brand': brand,
        'Price': price,
        'Description': description,
        'ImageUrl': imageUrl,
        'ProductLink': productLink,
        'CreatedAt': FieldValue.serverTimestamp(),
        'UpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Update an existing product
  Future<void> updateProduct(String docID, String name, String categoryId,
      String brand, double price, String description, String imageUrl, String productLink) async {
    try {
      await _productsCollection.doc(docID).update({
        'ProductName': name,
        'categoryId': categoryId,
        'Brand': brand,
        'Price': price,
        'Description': description,
        'ImageUrl': imageUrl,
        'ProductLink': productLink,
        'UpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete a product
  Future<void> deleteProduct(String docID) async {
    try {
      await _productsCollection.doc(docID).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Get a stream of all products
  Stream<QuerySnapshot> getProductsStream() {
    return _productsCollection.snapshots();
  }

  // Get products by category
  Stream<QuerySnapshot> getProductsByCategoryStream(String categoryId) {
    return _productsCollection.where('categoryId', isEqualTo: categoryId).snapshots();
  }

  // Get a single product by ID
  Future<DocumentSnapshot> getProductById(String docID) {
    return _productsCollection.doc(docID).get();
  }

  // Get category name by ID
  Future<String> getCategoryName(String categoryId) async {
    DocumentSnapshot categoryDoc = await _categoriesCollection.doc(categoryId).get();
    if (categoryDoc.exists) {
      return categoryDoc.get('Name') as String;
    } else {
      return 'Unknown Category';
    }
  }

  // Get all categories
  Stream<QuerySnapshot> getCategoriesStream() {
    return _categoriesCollection.snapshots();
  }

  // Add a new category
  Future<void> addCategory(String name, String description) async {
    try {
      await _categoriesCollection.add({
        'Name': name,
        'Description': description,
        'CreatedAt': FieldValue.serverTimestamp(),
        'UpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  // Update an existing category
  Future<void> updateCategory(String docID, String name, String description) async {
    try {
      await _categoriesCollection.doc(docID).update({
        'Name': name,
        'Description': description,
        'UpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // Delete a category
  Future<void> deleteCategory(String docID) async {
    try {
      // First, delete all products in this category
      WriteBatch batch = _db.batch();
      QuerySnapshot products = await _productsCollection.where('categoryId', isEqualTo: docID).get();
      for (var doc in products.docs) {
        batch.delete(doc.reference);
      }

      // Then delete the category
      batch.delete(_categoriesCollection.doc(docID));

      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }
}