import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:location_based_attendance_app/pages/Student/attendance_summary.dart';
import 'package:location_based_attendance_app/pages/Student/student_leave.dart';
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
    FontAwesomeIcons.check,
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
        height: 70,
        margin: const EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 24,  
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(40)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(2, 2), // changes position of shadow
            ),
          ],  
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(40)),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < navigationIcons.length; i++)...<Expanded>[
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
                                color: i == currentIndex ? Colors.black : Colors.grey,
                                size: i == currentIndex ? 30 : 26, 
                              ),
                              i == currentIndex ? Container(
                                margin: const EdgeInsets.only(top: 6),
                                height: 3,
                                width: 22,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(Radius.circular(40)),
                                  color: Colors.black,
                                ),
                              ) : const SizedBox(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ]
              ],
            ),
        ),
      ),
    );
  }
}