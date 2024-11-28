import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreConsultationService {
  final CollectionReference consultations = FirebaseFirestore.instance.collection('Consultations');

  Future<void> addConsultation(String userID, String designerID, DateTime scheduleDate, String status) async {
    await consultations.add({
      'UserID': userID,
      'DesignerID': designerID,
      'ScheduleDate': scheduleDate,
      'Status': status,
      'CreatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateConsultation(String docId, DateTime scheduleDate, String status) async {
    await consultations.doc(docId).update({
      'ScheduleDate': scheduleDate,
      'Status': status,
      'UpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteConsultation(String docId) async {
    await consultations.doc(docId).delete();
  }

  Stream<QuerySnapshot> getConsultationsStream() {
    return consultations.snapshots();
  }

  Future<DocumentSnapshot> getConsultationById(String docId) async {
    return await consultations.doc(docId).get();
  }
}
