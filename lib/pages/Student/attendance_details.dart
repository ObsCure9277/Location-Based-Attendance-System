import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Attendance Details",
          style: TextStyle(
            fontSize: 20,
            fontFamily: "NexaBold",
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          userId == null
              ? const Center(child: Text("User not logged in"))
              : FutureBuilder<List<String>>(
                future: getTimetableIdsForSubject(widget.subjectName ?? ''),
                builder: (context, timetableIdsSnapshot) {
                  if (!timetableIdsSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final timetableIds = timetableIdsSnapshot.data!;
                  if (timetableIds.isEmpty) {
                    return const Center(
                      child: Text("No attendance records found."),
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
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
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
                                startTime = timetableData['StartTime'] ?? '-';
                                endTime = timetableData['EndTime'] ?? '-';
                                classType =
                                    timetableData['Type'] ?? 'Unknown Type';
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (index == 0) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8.0,
                                        left: 10.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: const [
                                          SizedBox(width: 5),
                                          Text(
                                            'Type',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 15),
                                          Text(
                                            'Date',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 55),
                                          Text(
                                            'Time',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 115),
                                          Text(
                                            'Status',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  ListTile(
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
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
                                                      : (classType.isNotEmpty &&
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
                                                ? classType[0].toUpperCase()
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
                                                      : (classType.isNotEmpty &&
                                                          classType[0]
                                                                  .toUpperCase() ==
                                                              'L')
                                                      ? Colors.purple
                                                      : Colors.blueGrey,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 25),
                                        Text(
                                          date,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(width: 15),
                                        Text(
                                          '$startTime - $endTime',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(width: 15),
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
    );
  }
}
