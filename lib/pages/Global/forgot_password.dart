import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:location_based_attendance_app/widgets/field.dart';
import 'package:location_based_attendance_app/widgets/fieldtitle.dart';
import 'package:location_based_attendance_app/widgets/snackbar.dart';

class Forgotpassword extends StatefulWidget {
  final bool fromProfile;
  const Forgotpassword({super.key, this.fromProfile = false});

  @override
  State<Forgotpassword> createState() => _ForgotpasswordState();
}

class _ForgotpasswordState extends State<Forgotpassword> {
  double screenHeight = 0;
  double screenWidth = 0;
  final email = TextEditingController();

  resetpassword() async {
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: email.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.fromProfile ? "Reset Password" : "Forgot Password",
          style: TextStyle(
            fontSize: screenWidth * 0.05, 
            fontFamily: "NexaBold",
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05), // Was 20.0
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight * 0.0125), // Was 10
            customField(
              "Enter your registered email",
              email,
              Icons.email,
              screenHeight,
              screenWidth,
            ),
            SizedBox(height: screenHeight * 0.0125), // Was 10
            GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                if (email.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    CustomSnackBar().errorSnackBar(
                      message: "Email cannot be empty",
                    ),
                  );
                } else {
                  resetpassword();
                  ScaffoldMessenger.of(context).showSnackBar(
                    CustomSnackBar().successSnackBar(
                      message: "Reset link sent to your email",
                    ),
                  );
                }
              },
              child: buttonInText("Send Reset Link", screenHeight, screenWidth),
            ),
          ],
        ),
      ),
    );
  }
}
