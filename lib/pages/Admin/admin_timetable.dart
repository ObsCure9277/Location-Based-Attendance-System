import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location_based_attendance_app/pages/Global/splash.dart';
import 'package:location_based_attendance_app/widgets/form.dart';
import 'package:location_based_attendance_app/widgets/snackbar.dart';
import 'package:location_based_attendance_app/widgets/dialog.dart';

class Admintimetablepage extends StatefulWidget {
  const Admintimetablepage({super.key});

  @override
  State<Admintimetablepage> createState() => _AdmintimetablepageState();
}

class _AdmintimetablepageState extends State<Admintimetablepage> {
  double screenHeight = 0;
  double screenWidth = 0;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  DateTime selectedDate = DateTime.now();
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

  void deleteTimetable(DocumentSnapshot doc) async {
    // Delete all attendance records for this timetable
    final attendanceSnapshot =
        await firestore
            .collection('Attendance')
            .where('timetableId', isEqualTo: doc.id)
            .get();

    for (final attendanceDoc in attendanceSnapshot.docs) {
      await attendanceDoc.reference.delete();
    }

    await firestore.collection('Timetable').doc(doc.id).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      CustomSnackBar().successSnackBar(
        message: 'Timetable deleted successfully!',
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    String formattedDate = getFormattedDate(selectedDate);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Timetable",
          style: TextStyle(
            fontSize: screenWidth * 0.05,
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
          IconButton(
            icon: Icon(Icons.add),
            color: Colors.white,
            tooltip: 'Add Timetable',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TimetableForm()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.black87,
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.02,
              horizontal: screenWidth * 0.04,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    "${getDayName(selectedDate)}, $formattedDate",
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
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
                      return data['Date'] == formattedDate;
                    }).toList();

                // Sort by StartTime (earliest first)

                if (filteredDocs.isEmpty) {
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
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data = filteredDocs[index];
                    return Padding(
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => TimetableForm(docToEdit: data),
                            ),
                          );
                        },
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
                            SizedBox(width: screenWidth * 0.025),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      data['Type'] == 'L'
                                          ? Colors.black
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.03,
                                  ),
                                  border: Border.all(
                                    color:
                                        data['Type'] == 'L'
                                            ? Colors.white
                                            : Colors.black,
                                    width: screenWidth * 0.0025,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(screenWidth * 0.03),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Column(
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
                                            ],
                                          ),
                                          SizedBox(width: screenWidth * 0.01),
                                          Icon(
                                            Icons.home,
                                            color:
                                                data['Type'] == 'L'
                                                    ? Colors.white
                                                    : Colors.black,
                                            size: screenWidth * 0.05,
                                          ),
                                          SizedBox(width: screenWidth * 0.01),
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
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: screenWidth * 0.05,
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
                                                      fontSize:
                                                          screenWidth * 0.04,
                                                      color: Colors.black87,
                                                    ),
                                                    children: [
                                                      TextSpan(
                                                        text:
                                                            'Are you sure you want to delete this timetable for ',
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            '"${data['Subject'] ?? 'Unknown'}"',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontFamily:
                                                              'NexaBold',
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
                                                  deleteTimetable(data);
                                                } catch (e) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    CustomSnackBar().errorSnackBar(
                                                      message:
                                                          'Error deleting timetable: ${e.toString()}',
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: screenHeight * 0.01),
                                      Text(
                                        data['Subject'],
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.04,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              data['Type'] == 'L'
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.008),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            size: screenWidth * 0.04,
                                            color:
                                                data['Type'] == 'L'
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                          SizedBox(width: screenWidth * 0.01),
                                          Text(
                                            data['Lecturer'],
                                            style: TextStyle(
                                              color:
                                                  data['Type'] == 'L'
                                                      ? Colors.white
                                                      : Colors.black,
                                              fontSize: screenWidth * 0.035,
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
