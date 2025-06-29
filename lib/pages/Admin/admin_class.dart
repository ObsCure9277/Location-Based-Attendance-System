import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location_based_attendance_app/pages/Global/initial.dart';
import 'package:location_based_attendance_app/pages/Global/splash.dart';
import 'package:location_based_attendance_app/widgets/form.dart';
import 'package:location_based_attendance_app/widgets/snackbar.dart';

class Adminclasspage extends StatefulWidget {
  const Adminclasspage({super.key});

  @override
  State<Adminclasspage> createState() => _AdminclasspageState();
}

class _AdminclasspageState extends State<Adminclasspage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String _filterType = 'Alphabet';
  bool _ascending = true;

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Initial()),
      (route) => false,
    );
  }

  Future<void> deleteClassData(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final groupName = data['GroupName'] ?? '';
    final students = List<String>.from(data['Students'] ?? []);

    for (String student in students) {
      final match = RegExp(r'\(([^)]+)\)$').firstMatch(student);
      if (match != null) {
        final email = match.group(1)!;
        final query =
            await FirebaseFirestore.instance
                .collection('Student')
                .where('email', isEqualTo: email)
                .get();
        if (query.docs.isNotEmpty) {
          final studentDoc = query.docs.first;
          if ((studentDoc['GroupName'] ?? '') == groupName) {
            await studentDoc.reference.update({'GroupName': ''});
          }
        }
      }
    }
    await FirebaseFirestore.instance.collection('Class').doc(doc.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        title: const Text(
          "Tutorial Group",
          style: TextStyle(
            fontSize: 20,
            fontFamily: "NexaBold",
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Filter',
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              if (value == 'Alphabet' || value == 'StudentNumber') {
                setState(() {
                  _filterType = value;
                });
              } else if (value == 'Ascending') {
                setState(() {
                  _ascending = true;
                });
              } else if (value == 'Descending') {
                setState(() {
                  _ascending = false;
                });
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'Alphabet',
                    child: Text(
                      'Sort by Group Name',
                      style: TextStyle(fontFamily: 'NexaBold'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'StudentNumber',
                    child: Text(
                      'Sort by Student Number',
                      style: TextStyle(fontFamily: 'NexaBold'),
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'Ascending',
                    child: Text(
                      'Ascending',
                      style: TextStyle(fontFamily: 'NexaBold'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Descending',
                    child: Text(
                      'Descending',
                      style: TextStyle(fontFamily: 'NexaBold'),
                    ),
                  ),
                ],
          ),
          IconButton(
            icon: Icon(Icons.add),
            color: Colors.white,
            tooltip: 'Add Tutorial Group',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ClassForm()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('Class').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: SplashScreen());
          }

          final docs = snapshot.data!.docs;

          // Apply sorting based on filter
          List sortedDocs = List.from(docs);
          sortedDocs.sort((a, b) {
            if (_filterType == 'Alphabet') {
              final nameA = (a['GroupName'] ?? '').toString().toLowerCase();
              final nameB = (b['GroupName'] ?? '').toString().toLowerCase();
              return _ascending
                  ? nameA.compareTo(nameB)
                  : nameB.compareTo(nameA);
            } else if (_filterType == 'StudentNumber') {
              final studentsA = List<String>.from(a['Students'] ?? []);
              final studentsB = List<String>.from(b['Students'] ?? []);
              return _ascending
                  ? studentsA.length.compareTo(studentsB.length)
                  : studentsB.length.compareTo(studentsA.length);
            }
            return 0;
          });

          if (sortedDocs.isEmpty) {
            return const Center(
              child: Text(
                "No Class Found !",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "NexaBold",
                  color: Colors.black,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              var data = sortedDocs[index];
              final students = List<String>.from(data['Students'] ?? []);
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassForm(docToEdit: data),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['GroupName'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontFamily: "NexaBold",
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${students.length} student${students.length == 1 ? '' : 's'}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: "NexaRegular",
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await deleteClassData(data);
                              ScaffoldMessenger.of(context).showSnackBar(
                                CustomSnackBar().successSnackBar(
                                  message:
                                      'Tutorial Group deleted successfully!',
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
