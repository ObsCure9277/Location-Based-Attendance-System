import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:location_based_attendance_app/pages/Student/attendance_summary.dart';
import 'package:location_based_attendance_app/pages/Student/student_timetable.dart';
import 'package:location_based_attendance_app/service/location_service.dart';
import 'package:location_based_attendance_app/pages/Global/profile.dart';
import 'package:location_based_attendance_app/pages/Student/mark_attendance.dart';

class Studenthomepage extends StatefulWidget {
  const Studenthomepage({super.key});

  @override
  State<Studenthomepage> createState() => _StudenthomepageState();
}

class _StudenthomepageState extends State<Studenthomepage> {
  double screenHeight = 0;
  double screenWidth = 0;
  int currentIndex = 0;
  final user = FirebaseAuth.instance.currentUser;

  List<IconData> navigationIcons = [
    Icons.my_location,
    FontAwesomeIcons.calendarDays,
    FontAwesomeIcons.list,
    FontAwesomeIcons.user,
  ];

  @override
  void initState() {
    super.initState();
  }

  void signout() async {
    await FirebaseAuth.instance.signOut();
  }

  void startLocationService() async {
    LocationService().initialze();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          Attendancepage(),
          Studenttimetablepage(),
          AttendanceSummarypage(),
          Profilepage(),
        ],
      ),
      bottomNavigationBar: Container(
        height: screenHeight * 0.087, 
        margin: EdgeInsets.only(
          left: screenWidth * 0.03, 
          right: screenWidth * 0.03, 
          bottom: screenHeight * 0.03, 
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(
            Radius.circular(screenWidth * 0.1),
          ), 
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(2, 2), 
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.all(
            Radius.circular(screenWidth * 0.1),
          ), 
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < navigationIcons.length; i++) ...<Expanded>[
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        currentIndex = i;
                      });
                    },
                    child: Container(
                      height: screenHeight,
                      width: screenWidth,
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              navigationIcons[i],
                              color:
                                  i == currentIndex
                                      ? Colors.black
                                      : Colors.grey,
                              size:
                                  i == currentIndex
                                      ? screenWidth *
                                          0.075 
                                      : screenWidth * 0.065,
                            ),
                            i == currentIndex
                                ? Container(
                                  margin: EdgeInsets.only(
                                    top: screenHeight * 0.0075,
                                  ), 
                                  height: screenHeight * 0.00375, 
                                  width: screenWidth * 0.055, 
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(screenWidth * 0.1),
                                    ), 
                                    color: Colors.black,
                                  ),
                                )
                                : const SizedBox(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
