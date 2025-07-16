import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class AttendanceDetailspage extends StatefulWidget {
  final String? filterTimetableId;
  final String? subjectName;
  const AttendanceDetailspage({
    super.key,
    this.filterTimetableId,
    this.subjectName,
  });

  @override
  State<AttendanceDetailspage> createState() => _AttendanceDetailspageState();
}

class _AttendanceDetailspageState extends State<AttendanceDetailspage> {
  double screenHeight = 0.0;
  double screenWidth = 0.0;
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<String> fetchStudentName(String studentId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('Student')
            .doc(studentId)
            .get();
    return doc.data()?['name'] ?? 'Unknown Student';
  }

  Future<List<String>> getTimetableIdsForSubject(String subjectName) async {
    final timetableSnapshot =
        await FirebaseFirestore.instance
            .collection('Timetable')
            .where('Subject', isEqualTo: subjectName)
            .get();
    return timetableSnapshot.docs.map((doc) => doc.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Attendance Details",
          style: TextStyle(
            fontSize: screenWidth * 0.05,
            fontFamily: "NexaBold",
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Subject Header with Percentage
          if (widget.subjectName != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              color: Colors.black87,
              child: Column(
                children: [
                  // First row: Subject name and percent indicator
                  FutureBuilder<List<String>>(
                    future: getTimetableIdsForSubject(widget.subjectName ?? ''),
                    builder: (context, timetableIdsSnapshot) {
                      if (!timetableIdsSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final timetableIds = timetableIdsSnapshot.data!;

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
                                      (doc) =>
                                          doc['attendanceStatus'] == 'Absent',
                                    )
                                    .length;
                            final attended = total - absent;
                            percent = total == 0 ? 0.0 : attended / total;

                            // Match color thresholds with text conditions
                            if (percent >= 0.80) {
                              progressColor = Colors.green;
                            } else if (percent >= 0.5) {
                              progressColor = Colors.orange;
                            } else {
                              progressColor = Colors.red;
                            }
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.subjectName!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.05),
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 2.0,
                                      bottom: 2.0,
                                      right: 5.0,
                                    ),
                                    child: CircularPercentIndicator(
                                      radius: screenWidth * 0.09,
                                      lineWidth: screenWidth * 0.015,
                                      percent: percent.clamp(0.0, 1.0),
                                      center: Text(
                                        "${(percent * 100).toInt()}%",
                                        style: TextStyle(
                                          color: progressColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth * 0.04,
                                        ),
                                      ),
                                      progressColor: progressColor,
                                      backgroundColor: Colors.white,
                                      circularStrokeCap:
                                          CircularStrokeCap.round,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // Attendance Status Legend
                  Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.01),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: screenWidth * 0.06,
                              height: screenWidth * 0.06,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.green,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'P',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.03,
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            Text(
                              ': Present',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.05),
                            Container(
                              width: screenWidth * 0.06,
                              height: screenWidth * 0.06,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.red, width: 2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'A',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.03,
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            Text(
                              ': Absent',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.05),
                            Container(
                              width: screenWidth * 0.06,
                              height: screenWidth * 0.06,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.orange,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'L',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.03,
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            Text(
                              ': Leave',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  //Class Type with Attendance Counts
                  FutureBuilder<List<String>>(
                    future: getTimetableIdsForSubject(widget.subjectName ?? ''),
                    builder: (context, timetableIdsSnapshot) {
                      if (!timetableIdsSnapshot.hasData) {
                        return SizedBox(height: screenHeight * 0.04);
                      }

                      final timetableIds = timetableIdsSnapshot.data!;

                      return FutureBuilder<QuerySnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('Timetable')
                                .where(
                                  FieldPath.documentId,
                                  whereIn: timetableIds,
                                )
                                .get(),
                        builder: (context, timetableSnapshot) {
                          if (!timetableSnapshot.hasData) {
                            return SizedBox(height: screenHeight * 0.04);
                          }

                          // Separate timetable IDs by type
                          List<String> lectureTimetableIds = [];
                          List<String> tutorialTimetableIds = [];

                          for (var doc in timetableSnapshot.data!.docs) {
                            final type =
                                (doc['Type'] as String? ?? '').toUpperCase();
                            if (type == 'L') {
                              lectureTimetableIds.add(doc.id);
                            } else if (type == 'T') {
                              tutorialTimetableIds.add(doc.id);
                            }
                          }

                          return StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('Attendance')
                                    .where('studentId', isEqualTo: userId)
                                    .where('timetableId', whereIn: timetableIds)
                                    .snapshots(),
                            builder: (context, attendanceSnapshot) {
                              if (!attendanceSnapshot.hasData) {
                                return SizedBox(height: screenHeight * 0.04);
                              }

                              final docs = attendanceSnapshot.data!.docs;

                              // Filter and count attendance by class type
                              int lecturePresentCount = 0;
                              int lectureAbsentCount = 0;
                              int lectureLeaveCount = 0;
                              int tutorialPresentCount = 0;
                              int tutorialAbsentCount = 0;
                              int tutorialLeaveCount = 0;

                              for (var doc in docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                final timetableId =
                                    data['timetableId'] as String;
                                final status =
                                    data['attendanceStatus'] as String;

                                // Check if this is a lecture attendance
                                if (lectureTimetableIds.contains(timetableId)) {
                                  if (status == 'Present') {
                                    lecturePresentCount++;
                                  } else if (status == 'Absent') {
                                    lectureAbsentCount++;
                                  } else if (status == 'Leave') {
                                    lectureLeaveCount++;
                                  }
                                }
                                // Check if this is a tutorial attendance
                                else if (tutorialTimetableIds.contains(
                                  timetableId,
                                )) {
                                  if (status == 'Present') {
                                    tutorialPresentCount++;
                                  } else if (status == 'Absent') {
                                    tutorialAbsentCount++;
                                  } else if (status == 'Leave') {
                                    tutorialLeaveCount++;
                                  }
                                }
                              }
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Lecture Attendance count summary
                                  Row(
                                    children: [
                                      Container(
                                        width: screenWidth * 0.06,
                                        height: screenWidth * 0.06,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.purple,
                                            width: 2,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'L',
                                          style: TextStyle(
                                            color: Colors.purple,
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.03,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.02,
                                          vertical: screenHeight * 0.005,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '$lecturePresentCount', // UPDATED: Lecture-specific count
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: screenWidth * 0.03,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.01),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.02,
                                          vertical: screenHeight * 0.005,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '$lectureAbsentCount', // UPDATED: Lecture-specific count
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: screenWidth * 0.03,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.01),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.02,
                                          vertical: screenHeight * 0.005,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '$lectureLeaveCount', // UPDATED: Lecture-specific count
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: screenWidth * 0.03,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: screenWidth * 0.1),
                                  // Tutorial Attendance count summary
                                  Row(
                                    children: [
                                      Container(
                                        width: screenWidth * 0.06,
                                        height: screenWidth * 0.06,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.blue,
                                            width: 2,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'T',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.03,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.02,
                                          vertical: screenHeight * 0.005,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '$tutorialPresentCount', // UPDATED: Tutorial-specific count
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: screenWidth * 0.03,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.01),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.02,
                                          vertical: screenHeight * 0.005,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '$tutorialAbsentCount', // UPDATED: Tutorial-specific count
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: screenWidth * 0.03,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.01),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.02,
                                          vertical: screenHeight * 0.005,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '$tutorialLeaveCount', // UPDATED: Tutorial-specific count
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: screenWidth * 0.03,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

          // Main content - Attendance list
          Expanded(
            child:
                userId == null
                    ? const Center(child: Text("User not logged in"))
                    : FutureBuilder<List<String>>(
                      future: getTimetableIdsForSubject(
                        widget.subjectName ?? '',
                      ),
                      builder: (context, timetableIdsSnapshot) {
                        if (!timetableIdsSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final timetableIds = timetableIdsSnapshot.data!;
                        if (timetableIds.isEmpty) {
                          return const Center(
                            child: Text("No Attendance Records Found!"),
                          );
                        }
                        return StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('Attendance')
                                  .where('studentId', isEqualTo: userId)
                                  .where('timetableId', whereIn: timetableIds)
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final docs = snapshot.data?.docs ?? [];
                            if (docs.isEmpty) {
                              return const Center(
                                child: Text("No attendance records found."),
                              );
                            }
                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final data =
                                    docs[index].data() as Map<String, dynamic>;
                                final timetableId = data['timetableId'] ?? '';

                                return FutureBuilder<DocumentSnapshot>(
                                  future:
                                      FirebaseFirestore.instance
                                          .collection('Timetable')
                                          .doc(timetableId)
                                          .get(),
                                  builder: (context, timetableSnapshot) {
                                    String date = '-';
                                    String startTime = '-';
                                    String endTime = '-';
                                    String classType = 'Unknown Type';
                                    if (timetableSnapshot.hasData &&
                                        timetableSnapshot.data!.exists) {
                                      final timetableData =
                                          timetableSnapshot.data!.data()
                                              as Map<String, dynamic>;
                                      date = timetableData['Date'] ?? date;
                                      startTime =
                                          timetableData['StartTime'] ?? '-';
                                      endTime = timetableData['EndTime'] ?? '-';
                                      classType =
                                          timetableData['Type'] ??
                                          'Unknown Type';
                                    }
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (index == 0) ...[
                                          Container(
                                            color: Colors.black,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 10.0,
                                                left: 10.0,
                                                bottom: 10.0,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    width: screenWidth * 0.02,
                                                  ),
                                                  const Text(
                                                    'Type',
                                                    style: TextStyle(
                                                      fontFamily: 'NexaBold',
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: screenWidth * 0.070,
                                                  ),
                                                  const Text(
                                                    'Date',
                                                    style: TextStyle(
                                                      fontFamily: 'NexaBold',
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: screenWidth * 0.165,
                                                  ),
                                                  const Text(
                                                    'Time',
                                                    style: TextStyle(
                                                      fontFamily: 'NexaBold',
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: screenWidth * 0.26,
                                                  ),
                                                  const Text(
                                                    'Status',
                                                    style: TextStyle(
                                                      fontFamily: 'NexaBold',
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                        ListTile(
                                          title: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                width: screenWidth * 0.01,
                                              ),
                                              Container(
                                                width: 30,
                                                height: 30,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color:
                                                        (classType.isNotEmpty &&
                                                                classType[0]
                                                                        .toUpperCase() ==
                                                                    'T')
                                                            ? Colors.blue
                                                            : (classType
                                                                    .isNotEmpty &&
                                                                classType[0]
                                                                        .toUpperCase() ==
                                                                    'L')
                                                            ? Colors.purple
                                                            : Colors.blueGrey,
                                                    width: 2,
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  classType.isNotEmpty
                                                      ? classType[0]
                                                          .toUpperCase()
                                                      : '?',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        (classType.isNotEmpty &&
                                                                classType[0]
                                                                        .toUpperCase() ==
                                                                    'T')
                                                            ? Colors.blue
                                                            : (classType
                                                                    .isNotEmpty &&
                                                                classType[0]
                                                                        .toUpperCase() ==
                                                                    'L')
                                                            ? Colors.purple
                                                            : Colors.blueGrey,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: screenWidth * 0.07,
                                              ),
                                              Text(
                                                date,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(
                                                width: screenWidth * 0.08,
                                              ),
                                              Text(
                                                '$startTime - $endTime',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(
                                                width: screenWidth * 0.07,
                                              ),
                                              Container(
                                                width: 30,
                                                height: 30,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color:
                                                        (data['attendanceStatus'] ==
                                                                'Present')
                                                            ? Colors.green
                                                            : (data['attendanceStatus'] ==
                                                                'Leave')
                                                            ? Colors.orange
                                                            : (data['attendanceStatus'] ==
                                                                'Absent')
                                                            ? Colors.red
                                                            : Colors.black,
                                                    width: 2,
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  (data['attendanceStatus'] ==
                                                          'Present')
                                                      ? 'P'
                                                      : (data['attendanceStatus'] ==
                                                          'Leave')
                                                      ? 'L'
                                                      : (data['attendanceStatus'] ==
                                                          'Absent')
                                                      ? 'A'
                                                      : 'U',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color:
                                                        (data['attendanceStatus'] ==
                                                                'Present')
                                                            ? Colors.green
                                                            : (data['attendanceStatus'] ==
                                                                'Leave')
                                                            ? Colors.orange
                                                            : (data['attendanceStatus'] ==
                                                                'Absent')
                                                            ? Colors.red
                                                            : Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
