import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:location_based_attendance_app/service/auth_service.dart';
import 'package:location_based_attendance_app/pages/Global/login.dart';
import 'package:location_based_attendance_app/pages/Global/verify_email.dart';
import 'package:location_based_attendance_app/widgets/dropdownlist.dart';
import 'package:location_based_attendance_app/widgets/field.dart';
import 'package:location_based_attendance_app/widgets/fieldtitle.dart';
import 'package:location_based_attendance_app/widgets/snackbar.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  double screenHeight = 0;
  double screenWidth = 0;
  bool isObscure = true;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final passwordController = TextEditingController();
  String selectedRole = 'Student';
  final String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  final String phoneNumberPattern = r'^\+?[0-9]{7,15}$';

  register() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String phoneNumber = phoneNumberController.text.trim();
    String password = passwordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        phoneNumber.isEmpty ||
        password.isEmpty ||
        !RegExp(emailPattern).hasMatch(email) ||
        !RegExp(phoneNumberPattern).hasMatch(phoneNumber)) {
      return;
    }

    try {
      await authService.value.createAccount(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        role: selectedRole,
      );

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Use the rate-limited email service
          final emailSent = await authService.value.sendVerificationEmailWithRateLimit();
          if (!emailSent) {
            // If we couldn't send email due to rate limiting, show a message
            ScaffoldMessenger.of(context).showSnackBar(
              CustomSnackBar().infoSnackBar(
                message: "Account created. Please wait before requesting a verification email.",
              ),
            );
          }
        }

        // Navigate to verification page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Verifyemail()),
        );
      } catch (e) {
        debugPrint("Error in registration: $e");
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar().successSnackBar(message: 'Sign up successfully!'),
      );

      await Future.delayed(const Duration(seconds: 2));
    } on FirebaseAuthException catch (e) {
      String errorMessage = " ";
      if (e.code == 'email-already-in-use') {
        errorMessage = "This email is already in use.";
      } else if (e.code == 'weak-password') {
        errorMessage = "The password is too weak.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email address is not valid.";
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(CustomSnackBar().errorSnackBar(message: errorMessage));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            barTitle(
              selectedRole == "Student" ? "Student Register" : "Staff Register",
              screenHeight,
              screenWidth,
            ),
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.symmetric(horizontal: screenWidth / 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldTitle("Name", screenWidth),
                  customField(
                    "Enter your name",
                    nameController,
                    Icons.person,
                    screenHeight,
                    screenWidth,
                  ),
                  fieldTitle("Email", screenWidth),
                  customField(
                    "Enter your email",
                    emailController,
                    Icons.email,
                    screenHeight,
                    screenWidth,
                  ),
                  fieldTitle("Phone Number", screenWidth),
                  customField(
                    "Enter your phone number",
                    phoneNumberController,
                    Icons.phone,
                    screenHeight,
                    screenWidth,
                  ),
                  fieldTitle("Password", screenWidth),
                  customPasswordField(
                    "Enter your password",
                    passwordController,
                    isObscure,
                    Icons.lock,
                    () {
                      setState(() {
                        isObscure = !isObscure;
                      });
                    },
                    screenHeight,
                    screenWidth,
                  ),
                  fieldTitle("Role", screenWidth),
                  customDropdown(
                    "Select Role",
                    selectedRole,
                    ['Student', 'Staff'],
                    screenHeight,
                    screenWidth,
                    Icons.person,
                    (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                  GestureDetector(
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      String name = nameController.text.trim();
                      String email = emailController.text.trim();
                      String phoneNumber = phoneNumberController.text.trim();
                      String password = passwordController.text.trim();

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          CustomSnackBar().errorSnackBar(
                            message: "Name cannot be empty",
                          ),
                        );
                      } else if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          CustomSnackBar().errorSnackBar(
                            message: "Email cannot be empty",
                          ),
                        );
                      } else if (phoneNumber.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          CustomSnackBar().errorSnackBar(
                            message: "Phone number cannot be empty",
                          ),
                        );
                      } else if (password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          CustomSnackBar().errorSnackBar(
                            message: "Password cannot be empty",
                          ),
                        );
                      } else if (!RegExp(emailPattern).hasMatch(email)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          CustomSnackBar().errorSnackBar(
                            message:
                                "Enter your college email in the correct format (e.g. student123@college.edu.my)",
                          ),
                        );
                      } else if (!RegExp(
                        phoneNumberPattern,
                      ).hasMatch(phoneNumber)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          CustomSnackBar().errorSnackBar(
                            message:
                                "Enter your phone number in the correct format (e.g. +60123456789)",
                          ),
                        );
                      } else if (password.isNotEmpty && password.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          CustomSnackBar().errorSnackBar(
                            message:
                                "Password must be at least 6 characters long",
                          ),
                        );
                      } else {
                        await register();
                      }
                    },
                    child: buttonInText('SIGN UP', screenHeight, screenWidth),
                  ),
                  SizedBox(height: screenHeight * 0.025),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          letterSpacing: screenWidth * 0.0018,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Login()),
                          );
                        },
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontFamily: "NexaBold",
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.0375,
                            color: Colors.black,
                            letterSpacing: screenWidth * 0.0018,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
