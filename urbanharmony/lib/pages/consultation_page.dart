
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../services/firestore/firestore_consultation.dart';
import '../services/firestore/firestore_user.dart';
import '../services/firestore/firestore_designer.dart';

class ConsultationPage extends StatefulWidget {
  const ConsultationPage({Key? key}) : super(key: key);

  @override
  _ConsultationPageState createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  final FirestoreConsultationService consultationService = FirestoreConsultationService();
  final FirestoreUserService userService = FirestoreUserService();
  final FirestoreDesignerService designerService = FirestoreDesignerService();
  final TextEditingController statusController = TextEditingController();
  DateTime? selectedDate;
  String? selectedDocID;
  String? selectedUserID;
  String? selectedDesignerID;

  void openConsultationBox({String? docID}) async {
    if (docID != null) {
      try {
        DocumentSnapshot doc = await consultationService.getConsultationById(docID);
        final data = doc.data() as Map<String, dynamic>;
        statusController.text = data['Status'] ?? '';
        selectedDate = (data['ScheduleDate'] as Timestamp).toDate();
        selectedUserID = data['UserID'];
        selectedDesignerID = data['DesignerID'];
        selectedDocID = docID;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_to_load_consultation'.tr + ': $e'), // Dịch thông báo lỗi
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      statusController.clear();
      selectedDate = null;
      selectedUserID = null;
      selectedDesignerID = null;
      selectedDocID = null;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docID == null ? 'add_new_consultation'.tr : 'edit_consultation'.tr), // Dịch tiêu đề
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: userService.getUsersStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  return DropdownButtonFormField<String>(
                    value: selectedUserID,
                    onChanged: (newValue) {
                      setState(() {
                        selectedUserID = newValue;
                      });
                    },
                    items: snapshot.data!.docs.map((doc) {
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(doc['Username']),
                      );
                    }).toList(),
                    decoration: InputDecoration(labelText: 'user'.tr), // Dịch nhãn "Người dùng"
                  );
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: designerService.getDesignersStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  return DropdownButtonFormField<String>(
                    value: selectedDesignerID,
                    onChanged: (newValue) {
                      setState(() {
                        selectedDesignerID = newValue;
                      });
                    },
                    items: snapshot.data!.docs.map((doc) {
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(doc['FullName']),
                      );
                    }).toList(),
                    decoration: InputDecoration(labelText: 'designer'.tr), // Dịch nhãn "Nhà thiết kế"
                  );
                },
              ),
              TextFormField(
                controller: statusController,
                decoration: InputDecoration(labelText: 'status'.tr), // Dịch nhãn "Trạng thái"
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != selectedDate) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Text(selectedDate == null ? 'select_date'.tr : 'date'.tr + ': ${selectedDate!.toLocal()}'), // Dịch "Chọn ngày" và "Ngày:"
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              try {
                if (selectedDocID == null) {
                  await consultationService.addConsultation(
                    selectedUserID!,
                    selectedDesignerID!,
                    selectedDate!,
                    statusController.text,
                  );
                } else {
                  await consultationService.updateConsultation(
                    selectedDocID!,
                    selectedDate!,
                    statusController.text,
                  );
                }
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('failed_to_save_consultation'.tr + ': $e'), // Dịch thông báo lỗi
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(selectedDocID == null ? 'add'.tr : 'update'.tr), // Dịch "Thêm" và "Cập nhật"
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr), // Dịch "Hủy"
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('consultations'.tr), // Dịch tiêu đề "Tư vấn"
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openConsultationBox(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: consultationService.getConsultationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('an_error_occurred'.tr + ': ${snapshot.error}')); // Dịch thông báo lỗi
          }
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            List<QueryDocumentSnapshot> consultationsList = snapshot.data!.docs;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('user'.tr)), // Dịch "Người dùng"
                  DataColumn(label: Text('designer'.tr)), // Dịch "Nhà thiết kế"
                  DataColumn(label: Text('status'.tr)), // Dịch "Trạng thái"
                  DataColumn(label: Text('schedule_date'.tr)), // Dịch "Ngày lên lịch"
                  DataColumn(label: Text('actions'.tr)), // Dịch "Hành động"
                ],
                rows: consultationsList.map((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                  return DataRow(
                    cells: [
                      DataCell(FutureBuilder<DocumentSnapshot>(
                        future: userService.getUserById(data['UserID']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Text('Loading...');
                          }
                          if (snapshot.hasError) {
                            return const Text('Error');
                          }
                          final userData = snapshot.data?.data() as Map<String, dynamic>?;
                          return Text(userData?['Username'] ?? 'Unknown');
                        },
                      )),
                      DataCell(FutureBuilder<DocumentSnapshot>(
                        future: designerService.getDesignerById(data['DesignerID']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text('Loading...'.tr);
                          }
                          if (snapshot.hasError) {
                            return  Text('Error'.tr);
                          }
                          final designerData = snapshot.data?.data() as Map<String, dynamic>?;
                          return Text(designerData?['FullName'] ?? 'Unknown');
                        },
                      )),
                      DataCell(Text(data['Status'] ?? '')),
                      DataCell(Text((data['ScheduleDate'] as Timestamp).toDate().toLocal().toString())),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueGrey),
                            onPressed: () => openConsultationBox(docID: doc.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              try {
                                await consultationService.deleteConsultation(doc.id);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('failed_to_delete_consultation'.tr + ': $e'), // Dịch thông báo lỗi
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
            );
          }
          return Center(child: Text('no_consultations_available'.tr)); // Dịch "Không có tư vấn nào"
        },
      ),
    );
  }
}