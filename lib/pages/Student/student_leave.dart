import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'package:location_based_attendance_app/pages/Admin/leave_manage.dart';
import 'package:location_based_attendance_app/pages/Global/splash.dart';
import 'package:location_based_attendance_app/widgets/form.dart';

class Studentleavepage extends StatefulWidget {
  const Studentleavepage({super.key});

  @override
  State<Studentleavepage> createState() => _StudentleaveState();
}

class _StudentleaveState extends State<Studentleavepage> {
  double screenHeight = 0;
  double screenWidth = 0;
  bool _ascending = false;
  String _statusFilter = 'All';
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _studentName = '';

  @override
  void initState() {
    super.initState();
    _fetchStudentName();
  }

  Future<void> _fetchStudentName() async {
    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('Student')
          .doc(_currentUserId)
          .get();
      
      if (studentDoc.exists && mounted) {
        final studentData = studentDoc.data() as Map<String, dynamic>;
        
        // Debug: Print all fields in the student document
        print("Student document fields: ${studentData.keys.toList()}");
        
        setState(() {
          // Try both capitalization versions of the name field
          _studentName = studentData['name'] ?? studentData['Name'] ?? '';
          print("Fetched student name: '$_studentName'");
        });
      } else {
        print("Student document doesn't exist for ID: $_currentUserId");
      }
    } catch (e) {
      print("Error fetching student name: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    // Debug the current values
    print("Current values - Name: '$_studentName', ID: '$_currentUserId'");

    // Create the query
    Query leaveQuery = FirebaseFirestore.instance.collection('LeaveRequests');

    // Use name if available, otherwise use ID
    if (_studentName.isNotEmpty) {
      leaveQuery = leaveQuery.where('StudentName', isEqualTo: _studentName);
    } else {
      leaveQuery = leaveQuery.where('StudentID', isEqualTo: _currentUserId);
    }
    
    // Apply status filter if selected
    if (_statusFilter != 'All') {
      leaveQuery = leaveQuery.where('Status', isEqualTo: _statusFilter);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Leave Request",
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
              setState(() {
                if (value == 'Ascending') {
                  _ascending = true;
                } else if (value == 'Descending') {
                  _ascending = false;
                } else {
                  _statusFilter = value;
                }
              });
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'All',
                    child: Text(
                      'All Status',
                      style: TextStyle(
                        fontFamily: 'NexaBold',
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Pending',
                    child: Text(
                      'Pending',
                      style: TextStyle(
                        fontFamily: 'NexaBold',
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Approved',
                    child: Text(
                      'Approved',
                      style: TextStyle(
                        fontFamily: 'NexaBold',
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Rejected',
                    child: Text(
                      'Rejected',
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
                      'Request Date Ascending',
                      style: TextStyle(
                        fontFamily: 'NexaBold',
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Descending',
                    child: Text(
                      'Request Date Descending',
                      style: TextStyle(
                        fontFamily: 'NexaBold',
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                ],
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add Leave Request',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LeaveRequestForm()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: leaveQuery.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: SplashScreen());
          }
          final docs = snapshot.data!.docs;

          // Sort manually
          docs.sort((a, b) {
            final aDate = a['RequestDate'] ?? '';
            final bDate = b['RequestDate'] ?? '';
            return _ascending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
          });

          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No Leave Request Found !",
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
            padding: EdgeInsets.all(screenWidth * 0.04),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => StudentLeaveDetailPage(
                            data: data,
                            docId: docs[index].id,
                          ),
                    ),
                  );
                },
                child: Card(
                  color: Colors.black,
                  margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display status
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              data['Status'] == 'Approved'
                                  ? FontAwesomeIcons.circleCheck
                                  : data['Status'] == 'Rejected'
                                  ? FontAwesomeIcons.circleXmark
                                  : FontAwesomeIcons.clock,
                              color:
                                  data['Status'] == 'Approved'
                                      ? Colors.green
                                      : data['Status'] == 'Rejected'
                                      ? Colors.red
                                      : Colors.orange,
                              size: screenWidth * 0.05,
                            ),
                            SizedBox(width: screenWidth * 0.025),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                (data['Status'] ?? 'Pending').toString(),
                                style: TextStyle(
                                  fontFamily: "NexaBold",
                                  fontSize: screenWidth * 0.045,
                                  color:
                                      data['Status'] == 'Approved'
                                          ? Colors.green
                                          : data['Status'] == 'Rejected'
                                          ? Colors.red
                                          : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Row(
                          children: [
                            Text(
                              "From : ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: "NexaRegular",
                                color: Colors.white,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                            Text(
                              "${data['StartDate'] ?? ''}",
                              style: TextStyle(
                                fontFamily: "NexaRegular",
                                color: Colors.white,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              "To      : ",
                              style: TextStyle(
                                fontFamily: "NexaRegular",
                                color: Colors.white,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                            Text(
                              "${data['EndDate'] ?? ''}",
                              style: TextStyle(
                                fontFamily: "NexaRegular",
                                color: Colors.white,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "${data['RequestDate'] ?? ''}",
                              style: TextStyle(
                                fontFamily: "NexaRegular",
                                color: Colors.white,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                          ],
                        ),
                      ],
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
