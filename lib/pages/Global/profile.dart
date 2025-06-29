import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:location_based_attendance_app/pages/Global/forgot_password.dart';
import 'package:location_based_attendance_app/pages/Global/initial.dart';
import 'package:location_based_attendance_app/pages/Global/profile_details.dart';
import 'package:location_based_attendance_app/pages/Student/student_leave.dart';
import 'package:location_based_attendance_app/widgets/field.dart';

class Profilepage extends StatefulWidget {
  const Profilepage({super.key});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  double screenHeight = 0;
  double screenWidth = 0;
  String? selectedRole;

  @override
  void initState() {
    super.initState();
    fetchRole();
  }

  Future<void> fetchRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Try Staff first
      final staffDoc = await FirebaseFirestore.instance.collection('Staff').doc(user.uid).get();
      if (staffDoc.exists) {
        setState(() {
          selectedRole = 'Staff';
        });
        return;
      }
      // Try Student
      final studentDoc = await FirebaseFirestore.instance.collection('Student').doc(user.uid).get();
      if (studentDoc.exists) {
        setState(() {
          selectedRole = 'Student';
        });
        return;
      }
    }
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
          "User Profile",
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
              icon: Icons.person,
              title: 'Profile Details',
              iconColor: Colors.black,
              textColor: Colors.black,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileDetailspage(),
                  ),
                );
              },
            ),
            buildMenuTile(
              icon: Icons.lock_reset,
              title: 'Reset Password',
              iconColor: Colors.black,
              textColor: Colors.black,
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => const Forgotpassword(fromProfile: true),
                  )
                );
              },
            ),
            if (selectedRole != 'Staff')
              buildMenuTile(
                icon: FontAwesomeIcons.suitcase,
                title: 'Leave Request',
                iconColor: Colors.black,
                textColor: Colors.black,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Studentleavepage(),
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
