import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location_based_attendance_app/pages/Admin/leave_manage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:location_based_attendance_app/pages/Global/splash.dart';

class Adminleavepage extends StatefulWidget {
  const Adminleavepage({super.key});

  @override
  State<Adminleavepage> createState() => _AdminleavepageState();
}

class _AdminleavepageState extends State<Adminleavepage> {
  double screenHeight = 0;
  double screenWidth = 0;
  bool _ascending = false; // false = Descending by default
  String _statusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    Query leaveQuery = FirebaseFirestore.instance.collection('LeaveRequests');
    if (_statusFilter != 'All') {
      leaveQuery = leaveQuery.where('Status', isEqualTo: _statusFilter);
    }
    leaveQuery = leaveQuery.orderBy('RequestDate', descending: !_ascending);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: leaveQuery.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: SplashScreen());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No Leave Request Found!",
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
                          (context) => LeaveRequestDetailPage(
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
                            Text(
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
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Row(
                          children: [
                            Text(
                              "Name : ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: "NexaRegular",
                                color: Colors.white,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                            Text(
                              "${data['StudentName'] ?? ''}",
                              style: TextStyle(
                                fontFamily: "NexaRegular",
                                color: Colors.white,
                                fontSize: screenWidth * 0.035,
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
                        SizedBox(height: screenHeight * 0.01),
                        Row(
                          children: [
                            Text(
                              "To      : ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
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
