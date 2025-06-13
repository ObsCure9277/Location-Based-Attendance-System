import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:location_based_attendance_app/pages/verifyemail.dart';
import 'pages/homepage.dart';
import 'pages/loginpage.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context,snapshot){
          if (snapshot.hasData) {
            print(snapshot.data);
            if (snapshot.data!.emailVerified) {
              // User is signed in, navigate to the home page
              return Homepage();
            } else {
              return Verifyemail();
            }
          } else {
            // User is not signed in, navigate to the login page
            return KeyboardVisibilityProvider(child: const Login());
          }
        },
      ),
    );
  }
}