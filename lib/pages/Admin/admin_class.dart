import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location_based_attendance_app/pages/Global/splash.dart';
import 'package:location_based_attendance_app/widgets/form.dart';
import 'package:location_based_attendance_app/widgets/snackbar.dart';
import 'package:location_based_attendance_app/widgets/dialog.dart';

class Adminclasspage extends StatefulWidget {
  const Adminclasspage({super.key});

  @override
  State<Adminclasspage> createState() => _AdminclasspageState();
}

class _AdminclasspageState extends State<Adminclasspage> {
  double screenHeight = 0;
  double screenWidth = 0;
  String _filterType = 'Alphabet';
  bool _ascending = true;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

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
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Tutorial Group",
          style: TextStyle(
            fontSize: screenWidth * 0.05,
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
                  PopupMenuItem(
                    value: 'Alphabet',
                    child: Text(
                      'Sort by Group Name',
                      style: TextStyle(
                        fontFamily: 'NexaBold',
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'StudentNumber',
                    child: Text(
                      'Sort by Student Number',
                      style: TextStyle(
                        fontFamily: 'NexaBold',
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'Ascending',
                    child: Text(
                      'Ascending',
                      style: TextStyle(
                        fontFamily: 'NexaBold',
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Descending',
                    child: Text(
                      'Descending',
                      style: TextStyle(
                        fontFamily: 'NexaBold',
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                ],
          ),
          IconButton(
            icon: Icon(Icons.add, size: screenWidth * 0.06),
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
            return Center(
              child: Text(
                "No Class Found !",
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontFamily: "NexaBold",
                  color: Colors.black,
                  letterSpacing: screenWidth * 0.0018,
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
                padding: EdgeInsets.all(screenWidth * 0.02),
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
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      border: Border.all(
                        color: Colors.white,
                        width: screenWidth * 0.0025,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['GroupName'] ?? '',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontFamily: "NexaBold",
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: screenWidth * 0.005,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Text(
                                  "${students.length} student${students.length == 1 ? '' : 's'}",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontFamily: "NexaRegular",
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: screenWidth * 0.06,
                            ),
                            onPressed: () async {
                              bool
                              confirmDelete = await ConfirmDialog.showDeleteConfirmation(
                                context: context,
                                title: 'Confirm Deletion',
                                message: '',
                                customContent: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      color: Colors.black87,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            'Are you sure you want to delete Tutorial Group ',
                                      ),
                                      TextSpan(
                                        text:
                                            '"${data['GroupName'] ?? 'Unknown'}"',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'NexaBold',
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            ' ? This action cannot be undone.',
                                      ),
                                    ],
                                  ),
                                ),
                              );

                              if (confirmDelete) {
                                try {
                                  await deleteClassData(data);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    CustomSnackBar().successSnackBar(
                                      message:
                                          'Tutorial Group deleted successfully!',
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    CustomSnackBar().errorSnackBar(
                                      message:
                                          'Error deleting tutorial group: ${e.toString()}',
                                    ),
                                  );
                                }
                              }
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
