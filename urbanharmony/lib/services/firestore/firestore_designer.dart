import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreDesignerService {
  final CollectionReference designers = FirebaseFirestore.instance.collection('Designers');

  Future<void> addDesigner(String userID, String fullName, int yearsOfExperience, String specialization) async {
    await designers.add({
      'UserID': userID,
      'FullName': fullName,
      'YearsOfExperience': yearsOfExperience,
      'Specialization': specialization,
    });
  }

  Future<void> updateDesigner(String docId, String fullName, int yearsOfExperience, String specialization) async {
    await designers.doc(docId).update({
      'FullName': fullName,
      'YearsOfExperience': yearsOfExperience,
      'Specialization': specialization,
    });
  }

  Future<void> deleteDesigner(String docId) async {
    await designers.doc(docId).delete();
  }

  Stream<QuerySnapshot> getDesignersStream() {
    return designers.snapshots();
  }

  Future<DocumentSnapshot> getDesignerById(String docId) async {
    return await designers.doc(docId).get();
  }
}