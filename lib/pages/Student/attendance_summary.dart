import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location_based_attendance_app/pages/Global/splash.dart';
import 'attendance_details.dart';
import 'package:percent_indicator/percent_indicator.dart';

class AttendanceSummarypage extends StatefulWidget {
  const AttendanceSummarypage({super.key});

  @override
  State<AttendanceSummarypage> createState() => _AttendanceSummarypageState();
}

class _AttendanceSummarypageState extends State<AttendanceSummarypage> {
  double screenHeight = 0;
  double screenWidth = 0;
  String? userId;
  String? groupName;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    fetchGroupName();
  }

  Future<void> fetchGroupName() async {
    if (userId == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('Student')
            .doc(userId)
            .get();
    setState(() {
      groupName = doc.data()?['GroupName'];
    });
  }

  Future<double> getAttendancePercent(List<String> timetableIds) async {
    // All attendance for these timetables
    final totalSnapshot =
        await FirebaseFirestore.instance
            .collection('Attendance')
            .where('timetableId', whereIn: timetableIds)
            .get();

    // Attendance records with status 'Absent'
    final absentSnapshot =
        await FirebaseFirestore.instance
            .collection('Attendance')
            .where('timetableId', whereIn: timetableIds)
            .where('studentId', isEqualTo: userId)
            .where('attendanceStatus', isEqualTo: 'Absent')
            .get();

    final total =
        totalSnapshot.docs.where((doc) => doc['studentId'] == userId).length;
    final absent = absentSnapshot.docs.length;
    final attended = total - absent;

    if (total == 0) return 0.0;
    return attended / total;
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    if (userId == null || groupName == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        title: Text(
          "Attendance Summary",
          style: TextStyle(
            fontSize: screenWidth * 0.05,
            fontFamily: "NexaBold",
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('Timetable')
                .where('GroupNames', arrayContains: groupName)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SplashScreen());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No Attendance Found!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.04,
                ),
              ),
            );
          }

          // Group timetables by subject name
          final Map<String, List<QueryDocumentSnapshot>> grouped = {};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final subjectName = data['Subject'] ?? 'Unknown Subject';
            grouped.putIfAbsent(subjectName, () => []).add(doc);
          }

          return ListView(
            padding: EdgeInsets.all(screenWidth * 0.04), // Responsive padding
            children:
                grouped.entries.map((entry) {
                  final subjectName = entry.key;
                  final timetableIds = entry.value.map((e) => e.id).toList();
                  // Use StreamBuilder for real-time attendance percent
                  return StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('Attendance')
                            .where('timetableId', whereIn: timetableIds)
                            .where('studentId', isEqualTo: userId)
                            .snapshots(),
                    builder: (context, attendanceSnapshot) {
                      double percent = 0.0;
                      Color progressColor = Colors.red;

                      if (attendanceSnapshot.hasData) {
                        final docs = attendanceSnapshot.data!.docs;
                        final total = docs.length;
                        final absent =
                            docs
                                .where(
                                  (doc) => doc['attendanceStatus'] == 'Absent',
                                )
                                .length;
                        final attended = total - absent;
                        percent = total == 0 ? 0.0 : attended / total;
                        progressColor =
                            percent >= 0.80
                                ? Colors.green
                                : (percent >= 0.5 ? Colors.orange : Colors.red);
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AttendanceDetailspage(
                                    filterTimetableId: timetableIds.first,
                                    subjectName: subjectName,
                                  ),
                            ),
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.only(
                            bottom: screenHeight * 0.02,
                          ), // Responsive margin
                          padding: EdgeInsets.all(
                            screenWidth * 0.04,
                          ), // Responsive padding
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.03,
                            ), // Responsive border radius
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  subjectName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        screenWidth *
                                        0.04, // Responsive font size
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              CircularPercentIndicator(
                                radius:
                                    screenWidth * 0.075, // Responsive radius
                                lineWidth:
                                    screenWidth *
                                    0.015, // Responsive line width
                                percent: percent.clamp(0.0, 1.0),
                                center: Text(
                                  "${(percent * 100).toInt()}%",
                                  style: TextStyle(
                                    color: progressColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        screenWidth *
                                        0.035, // Responsive font size
                                  ),
                                ),
                                progressColor: progressColor,
                                backgroundColor: Colors.grey.shade300,
                                circularStrokeCap: CircularStrokeCap.round,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
          );
        },
      ),
    );
  }
}
