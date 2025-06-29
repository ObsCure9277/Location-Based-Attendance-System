import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location_based_attendance_app/pages/Global/initial.dart';
import 'package:location_based_attendance_app/pages/Global/splash.dart';
import 'package:location_based_attendance_app/widgets/form.dart';
import 'package:location_based_attendance_app/widgets/snackbar.dart';

class Admingeofencepage extends StatefulWidget {
  const Admingeofencepage({super.key});

  @override
  State<Admingeofencepage> createState() => _AdmingeofencepageState();
}

class _AdmingeofencepageState extends State<Admingeofencepage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  double screenHeight = 0;
  double screenWidth = 0;
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
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

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
          "Location",
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
              if (value == 'Alphabet' || value == 'Radius') {
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
                      'Sort by Name',
                      style: TextStyle(fontFamily: 'NexaBold'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'Radius',
                    child: Text(
                      'Sort by Radius',
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
            tooltip: 'Add Location',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LocationForm()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            color: Colors.red,
            tooltip: 'Sign Out',
            onPressed: () => logout(context),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('Location').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: SplashScreen());
          }

          List docs = snapshot.data!.docs;

          // Apply sorting based on filter
          docs.sort((a, b) {
            if (_filterType == 'Alphabet') {
              final nameA = (a['locationName'] ?? '').toString().toLowerCase();
              final nameB = (b['locationName'] ?? '').toString().toLowerCase();
              return _ascending
                  ? nameA.compareTo(nameB)
                  : nameB.compareTo(nameA);
            } else if (_filterType == 'Radius') {
              final radiusA =
                  (a['radius'] ?? 0) is num
                      ? (a['radius'] ?? 0).toDouble()
                      : double.tryParse(a['radius'].toString()) ?? 0.0;
              final radiusB =
                  (b['radius'] ?? 0) is num
                      ? (b['radius'] ?? 0).toDouble()
                      : double.tryParse(b['radius'].toString()) ?? 0.0;
              return _ascending
                  ? radiusA.compareTo(radiusB)
                  : radiusB.compareTo(radiusA);
            }
            return 0;
          });

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No Location Found !",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "NexaBold",
                  color: Colors.black,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationForm(docToEdit: data),
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
                                  data['locationName'] ?? '',
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
                                  "Radius: ${((data['radius'] ?? 0) is num ? (data['radius'] ?? 0).round() : int.tryParse(data['radius'].toString()) ?? 0)} m",
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
                              await FirebaseFirestore.instance
                                  .collection('Location')
                                  .doc(data.id)
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                CustomSnackBar().successSnackBar(
                                  message: 'Location deleted successfully!',
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
