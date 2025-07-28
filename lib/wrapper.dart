import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:location_based_attendance_app/pages/Global/initial.dart';
import 'package:location_based_attendance_app/service/auth_service.dart';
import 'package:location_based_attendance_app/pages/Global/splash.dart';
import 'package:location_based_attendance_app/pages/Staff/staff_home.dart';
import 'package:location_based_attendance_app/pages/Global/verify_email.dart';
import 'package:location_based_attendance_app/pages/Student/student_home.dart';

class Wrapper extends StatelessWidget {
  Wrapper({super.key});
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<String> getCurrentUserRole(String uid) async {
    final DocumentSnapshot studentDoc =
        await firestore.collection('Student').doc(uid).get();
        final DocumentSnapshot staffDoc =
        await firestore.collection('Staff').doc(uid).get();
    if (studentDoc.exists) {
      return 'Student';
    } else if (staffDoc.exists) {
      return 'Staff';
    }
    return 'Admin';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: authService,
      builder: (context, authService, child) {
        return StreamBuilder<User?>(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            final user = snapshot.data;
            if (user != null) {
              if (!user.emailVerified) {
                return const Verifyemail();
              }

              return FutureBuilder(
                future: getCurrentUserRole(user.uid),
                builder: (context, roleSnapshot) {
                  if (roleSnapshot.connectionState == ConnectionState.waiting) {
                    return const SplashScreen();
                  }

                  if (roleSnapshot.hasData && roleSnapshot.data != null) {
                    final role = roleSnapshot.data;
                    return role == 'Student'
                        ? const Studenthomepage()
                        : const Staffhomepage();
                  }
                  return const Initial();
                },
              );
            }
            return const Initial();
          },
        );
      },
    );
  }
}
