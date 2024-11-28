import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../services/firestore/firestore_designer.dart';
import '../services/firestore/firestore_user.dart';

class DesignersPage extends StatefulWidget {
  const DesignersPage({Key? key}) : super(key: key);

  @override
  _DesignersPageState createState() => _DesignersPageState();
}

class _DesignersPageState extends State<DesignersPage> {
  final FirestoreDesignerService firestoreService = FirestoreDesignerService();
  final FirestoreUserService userService = FirestoreUserService();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController yearsOfExperienceController = TextEditingController();
  final TextEditingController specializationController = TextEditingController();
  String? selectedDocID;
  String? selectedUserID;

  void openDesignerBox({String? docID}) async {
    if (docID != null) {
      try {
        DocumentSnapshot doc = await firestoreService.getDesignerById(docID);
        final data = doc.data() as Map<String, dynamic>;
        fullNameController.text = data['FullName'.tr] ?? '';
        yearsOfExperienceController.text = data['YearsOfExperience'.tr]?.toString() ?? '';
        specializationController.text = data['Specialization'.tr] ?? '';
        selectedUserID = data['UserID'.tr];
        selectedDocID = docID;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load designer: $e'.tr),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      fullNameController.clear();
      yearsOfExperienceController.clear();
      specializationController.clear();
      selectedUserID = null;
      selectedDocID = null;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docID == null ? 'Add New Designer'.tr : 'Edit Designer'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: userService.getUsersStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
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
                        child: Text(doc['Username'.tr]),
                      );
                    }).toList(),
                    decoration: InputDecoration(labelText: 'User'.tr),
                  );
                },
              ),
              TextField(
                controller: fullNameController,
                decoration: InputDecoration(labelText: 'Full Name'.tr),
              ),
              TextField(
                controller: yearsOfExperienceController,
                decoration: InputDecoration(labelText: 'Years of Experience'.tr),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: specializationController,
                decoration: InputDecoration(labelText: 'Specialization'.tr),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              try {
                if (selectedDocID == null) {
                  await firestoreService.addDesigner(
                    selectedUserID!,
                    fullNameController.text,
                    int.parse(yearsOfExperienceController.text),
                    specializationController.text,
                  );
                } else {
                  await firestoreService.updateDesigner(
                    selectedDocID!,
                    fullNameController.text,
                    int.parse(yearsOfExperienceController.text),
                    specializationController.text,
                  );
                }
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save designer: $e'.tr),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(selectedDocID == null ? 'Add'.tr : 'Update'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text('Cancel'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('Designers'.tr),
        backgroundColor: Colors.purple,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openDesignerBox(),
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getDesignersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          }
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            List<QueryDocumentSnapshot> designersList = snapshot.data!.docs;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns:  [
                  DataColumn(label: Text('User'.tr)),
                  DataColumn(label: Text('Full Name'.tr)),
                  DataColumn(label: Text('Years of Experience'.tr)),
                  DataColumn(label: Text('Specialization'.tr)),
                  DataColumn(label: Text('Actions'.tr)),
                ],
                rows: designersList.map((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                  return DataRow(
                    cells: [
                      DataCell(FutureBuilder<DocumentSnapshot>(
                        future: userService.getUserById(data['UserID']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text('Loading...'.tr);
                          }
                          if (snapshot.hasError) {
                            return Text('Error'.tr);
                          }
                          final userData = snapshot.data?.data() as Map<String, dynamic>?;
                          return Text(userData?['Username'] ?? 'Unknown');
                        },
                      )),
                      DataCell(Text(data['FullName'.tr] ?? '')),
                      DataCell(Text('${data['YearsOfExperience'.tr] ?? 0}')),
                      DataCell(Text(data['Specialization'.tr] ?? '')),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueGrey),
                            onPressed: () => openDesignerBox(docID: doc.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              try {
                                await firestoreService.deleteDesigner(doc.id);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to delete designer: $e'.tr),
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
          return  Center(child: Text('No designers available.'.tr));
        },
      ),
    );
  }
}
