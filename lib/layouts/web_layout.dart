import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:location_based_attendance_app/pages/Admin/admin_class.dart';
import 'package:location_based_attendance_app/pages/Admin/admin_geofence.dart';
import 'package:location_based_attendance_app/pages/Admin/admin_leave.dart';
import 'package:location_based_attendance_app/pages/Admin/admin_timetable.dart';
import 'package:location_based_attendance_app/pages/Global/initial.dart';
import 'package:location_based_attendance_app/pages/Global/profile_details.dart';
import 'package:location_based_attendance_app/pages/Staff/staff_dashboard.dart';
import 'package:location_based_attendance_app/pages/Staff/staff_timetable.dart';
import 'package:location_based_attendance_app/pages/Student/attendance_summary.dart';
import 'package:location_based_attendance_app/pages/Student/mark_attendance.dart';
import 'package:location_based_attendance_app/pages/Student/student_leave.dart';
import 'package:location_based_attendance_app/pages/Student/student_timetable.dart';

class WebLayout extends StatefulWidget {
  final Widget mobileView;
  final String title;
  final List<Widget>? actions;
  final String userRole;
  
  const WebLayout({
    Key? key, 
    required this.mobileView,
    required this.title,
    this.actions,
    this.userRole = 'Student',
  }) : super(key: key);

  @override
  State<WebLayout> createState() => _WebLayoutState();
}

class _WebLayoutState extends State<WebLayout> {
  int _selectedIndex = 0;
  late List<Map<String, dynamic>> _navItems;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initNavigation();
  }
  
  void _initNavigation() {
    if (widget.userRole == 'Admin') {
      _navItems = [
        {'title': 'Leave Requests', 'icon': FontAwesomeIcons.suitcase},
        {'title': 'Timetable', 'icon': FontAwesomeIcons.calendarDays},
        {'title': 'Tutorial Groups', 'icon': FontAwesomeIcons.userGroup},
        {'title': 'Locations', 'icon': FontAwesomeIcons.locationDot},
        {'title': 'Profile', 'icon': FontAwesomeIcons.user},
      ];
      _screens = [
        const Adminleavepage(),
        const Admintimetablepage(),
        const Adminclasspage(),
        const Admingeofencepage(),
        const ProfileDetailspage(),
      ];
    } else if (widget.userRole == 'Staff') {
      _navItems = [
        {'title': 'Timetable', 'icon': FontAwesomeIcons.calendarDays},
        {'title': 'Dashboard', 'icon': FontAwesomeIcons.list},
        {'title': 'Profile', 'icon': FontAwesomeIcons.user},
      ];
      _screens = [
        const Stafftimetablepage(),
        const StaffDashboardpage(),
        const ProfileDetailspage(),
      ];
    } else {
      // Student
      _navItems = [
        {'title': 'Mark Attendance', 'icon': Icons.my_location},
        {'title': 'Timetable', 'icon': FontAwesomeIcons.calendarDays},
        {'title': 'Attendance Summary', 'icon': FontAwesomeIcons.list},
        {'title': 'Leave Requests', 'icon': FontAwesomeIcons.suitcase},
        {'title': 'Profile', 'icon': FontAwesomeIcons.user},
      ];
      _screens = [
        const Attendancepage(),
        const Studenttimetablepage(),
        const AttendanceSummarypage(),
        const Studentleavepage(),
        const ProfileDetailspage(),
      ];
    }
  }
  
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Initial()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Row(
        children: [
          // Left sidebar navigation
          Container(
            width: 250,
            color: Colors.black,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'GeoMark',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: "NexaBold",
                        ),
                      ),
                      Text(
                        'No Punch, Just Presence',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          fontFamily: "NexaRegular",
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(color: Colors.white24, height: 1),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: _navItems.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(
                          _navItems[index]['icon'],
                          color: _selectedIndex == index ? Colors.white : Colors.white70,
                        ),
                        title: Text(
                          _navItems[index]['title'],
                          style: TextStyle(
                            color: _selectedIndex == index ? Colors.white : Colors.white70,
                            fontFamily: "NexaRegular",
                            fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: _selectedIndex == index,
                        selectedTileColor: Colors.white.withOpacity(0.1),
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                      );
                    },
                  ),
                ),
                
                const Divider(color: Colors.white24, height: 1),
                
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white70),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white70,
                      fontFamily: "NexaRegular",
                    ),
                  ),
                  onTap: () => _logout(context),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // Main content area
          Expanded(
            child: Column(
              children: [
                // App bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        _navItems[_selectedIndex]['title'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: "NexaBold",
                        ),
                      ),
                      Spacer(),
                      if (widget.actions != null) ...widget.actions!,
                    ],
                  ),
                ),
                
                // Page content
                Expanded(
                  child: Container(
                    color: Colors.grey[100],
                    padding: const EdgeInsets.all(20),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _screens[_selectedIndex],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}