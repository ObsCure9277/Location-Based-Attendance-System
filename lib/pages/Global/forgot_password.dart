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
  bool _isLoading = false;

  Future<bool> resetpassword() async {
    try {
      // Basic email validation
      String emailText = email.text.trim();
      if (emailText.isEmpty || !emailText.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar().errorSnackBar(
            message: "Please enter a valid email address",
          ),
        );
        return false;
      }

      // Send reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailText,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No user found with this email.";
          break;
        case 'invalid-email':
          errorMessage = "The email address is invalid.";
          break;
        case 'too-many-requests':
          errorMessage = "Too many requests. Try again later.";
          break;
        default:
          errorMessage = "Error: ${e.message}";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar().errorSnackBar(message: errorMessage),
      );
      return false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar().errorSnackBar(message: "Error: $e"),
      );
      return false;
    }
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
              onTap: _isLoading
                  ? null
                  : () async {
                      FocusScope.of(context).unfocus();

                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        if (email.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            CustomSnackBar().errorSnackBar(
                              message: "Email cannot be empty",
                            ),
                          );
                        } else {
                          bool success = await resetpassword();
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              CustomSnackBar().successSnackBar(
                                message: "Reset link sent to your email",
                              ),
                            );
                          }
                        }
                      } finally {
                        // Hide loading indicator
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
              child: _isLoading
                  ? Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  : buttonInText("Send Reset Link", screenHeight, screenWidth),
            ),
          ],
        ),
      ),
    );
  }
}
