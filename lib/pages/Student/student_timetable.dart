import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location_based_attendance_app/pages/Global/splash.dart';

class Studenttimetablepage extends StatefulWidget {
  const Studenttimetablepage({super.key});

  @override
  State<Studenttimetablepage> createState() => _StudenttimetablepageState();
}

class _StudenttimetablepageState extends State<Studenttimetablepage> {
  String getFormattedDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
  }

  String getDayName(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
  }

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  DateTime selectedDate = DateTime.now();

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  List<String> studentGroups = [];
  String studentGroupName = '';

  @override
  void initState() {
    super.initState();
    fetchStudentGroups();
  }

  Future<void> fetchStudentGroups() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('Student')
              .doc(user.uid)
              .get();
      setState(() {
        studentGroupName = doc['GroupName'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = getFormattedDate(selectedDate);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        title: Text(
          "Class Timetable",
          style: TextStyle(
            fontSize: 20,
            fontFamily: "NexaBold",
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            color: Colors.white,
            tooltip: 'Select date',
            onPressed: pickDate,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    "${getDayName(selectedDate)}, $formattedDate",
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: "NexaRegular",
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  firestore
                      .collection('Timetable')
                      .orderBy('StartTime')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: SplashScreen());
                }

                final docs = snapshot.data!.docs;

                // Filter by selected date
                final filteredDocs =
                    docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final timetableGroups =
                          data['GroupNames'] != null
                              ? List<String>.from(data['GroupNames'])
                              : [];
                      return data['Date'] == formattedDate &&
                          timetableGroups.contains(studentGroupName);
                    }).toList();

                // Sort by StartTime (earliest first)
                filteredDocs.sort((a, b) {
                  final aTime =
                      (a.data() as Map<String, dynamic>)['StartTime'] as String;
                  final bTime =
                      (b.data() as Map<String, dynamic>)['StartTime'] as String;

                  // Parse time string to DateTime for comparison
                  TimeOfDay parseTime(String timeStr) {
                    final parts = timeStr.split(' ');
                    final hm = parts[0].split(':');
                    int hour = int.parse(hm[0]);
                    final minute = int.parse(hm[1]);
                    final isPM =
                        parts.length > 1 && parts[1].toUpperCase() == 'PM';
                    if (isPM && hour != 12) hour += 12;
                    if (!isPM && hour == 12) hour = 0;
                    return TimeOfDay(hour: hour, minute: minute);
                  }

                  final aParsed = parseTime(aTime);
                  final bParsed = parseTime(bTime);

                  if (aParsed.hour != bParsed.hour) {
                    return aParsed.hour.compareTo(bParsed.hour);
                  }
                  return aParsed.minute.compareTo(bParsed.minute);
                });

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No Record Found !",
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: "NexaBold",
                        color: Colors.black,
                        letterSpacing: 0.7,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data = filteredDocs[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {},
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${data['StartTime']}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  "${data['EndTime']}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      data['Type'] == 'L'
                                          ? Colors.black
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        data['Type'] == 'L'
                                            ? Colors.white
                                            : Colors.black,
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                data['Type'] == 'L'
                                                    ? Colors.white
                                                    : Colors.black,
                                            child: Text(
                                              data['Type'],
                                              style: TextStyle(
                                                color:
                                                    data['Type'] == 'L'
                                                        ? Colors.black
                                                        : Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.home,
                                            color:
                                                data['Type'] == 'L'
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            data['locationName'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  data['Type'] == 'L'
                                                      ? Colors.white
                                                      : Colors.black,
                                            ),
                                          ),
                                          Spacer(),
                                          StreamBuilder<QuerySnapshot>(
                                            stream:
                                                FirebaseFirestore.instance
                                                    .collection('Attendance')
                                                    .where(
                                                      'studentId',
                                                      isEqualTo:
                                                          FirebaseAuth
                                                              .instance
                                                              .currentUser!
                                                              .uid,
                                                    )
                                                    .where(
                                                      'timetableId',
                                                      isEqualTo: data.id,
                                                    )
                                                    .snapshots(),
                                            builder: (
                                              context,
                                              attendanceSnapshot,
                                            ) {
                                              if (attendanceSnapshot.hasData &&
                                                  attendanceSnapshot
                                                      .data!
                                                      .docs
                                                      .isNotEmpty) {
                                                final attendanceData =
                                                    attendanceSnapshot
                                                            .data!
                                                            .docs
                                                            .first
                                                            .data()
                                                        as Map<String, dynamic>;
                                                final status =
                                                    attendanceData['attendanceStatus'];
                                                if (status == 'Present') {
                                                  return const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                    size: 28,
                                                  );
                                                } else if (status == 'Absent') {
                                                  return const Icon(
                                                    Icons.cancel,
                                                    color: Colors.red,
                                                    size: 28,
                                                  );
                                                } else if (status == 'Leave') {
                                                  return const Icon(
                                                    Icons.work,
                                                    color: Colors.orange,
                                                    size: 28,
                                                  );
                                                }
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        data['Subject'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              data['Type'] == 'L'
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            size: 16,
                                            color:
                                                data['Type'] == 'L'
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            data['Lecturer'],
                                            style: TextStyle(
                                              color:
                                                  data['Type'] == 'L'
                                                      ? Colors.white
                                                      : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
