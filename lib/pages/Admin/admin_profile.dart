import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:location_based_attendance_app/pages/Admin/admin_class.dart';
import 'package:location_based_attendance_app/pages/Admin/admin_geofence.dart';
import 'package:location_based_attendance_app/pages/Admin/admin_timetable.dart';
import 'package:location_based_attendance_app/pages/Global/initial.dart';
import 'package:location_based_attendance_app/widgets/field.dart';

class AdminProfilepage extends StatefulWidget {
  const AdminProfilepage({super.key});

  @override
  State<AdminProfilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<AdminProfilepage> {
  double screenHeight = 0;
  double screenWidth = 0;
  String? selectedRole;

  @override
  void initState() {
    super.initState();
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Initial()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            fontSize: 20,
            fontFamily: "NexaBold",
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          vertical: screenHeight / 50,
          horizontal: screenWidth / 20,
        ),
        child: Column(
          children: [
            buildMenuTile(
              icon: FontAwesomeIcons.calendarDays,
              title: 'Timetable',
              iconColor: Colors.black,
              textColor: Colors.black,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Admintimetablepage(),
                  ),
                );
              },
            ),
            buildMenuTile(
              icon: FontAwesomeIcons.userGroup,
              title: 'Tutorial Group',
              iconColor: Colors.black,
              textColor: Colors.black,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Adminclasspage(),
                  ),
                );
              },
            ),
            buildMenuTile(
              icon: FontAwesomeIcons.locationDot,
              title: 'Location',
              iconColor: Colors.black,
              textColor: Colors.black,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Admingeofencepage(),
                  ),
                );
              },
            ),
            buildMenuTile(
              icon: Icons.logout,
              title: 'Logout',
              iconColor: Colors.redAccent,
              textColor: Colors.black,
              onTap: () {
                logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
