import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:location_based_attendance_app/pages/Admin/admin_home.dart';
import 'package:location_based_attendance_app/pages/Global/forgot_password.dart';
import 'package:location_based_attendance_app/service/auth_service.dart';
import 'package:location_based_attendance_app/pages/Global/sign_up.dart';
import 'package:location_based_attendance_app/pages/Student/student_home.dart';
import 'package:location_based_attendance_app/pages/Staff/staff_home.dart';
import 'package:location_based_attendance_app/pages/Global/verify_email.dart';
import 'package:location_based_attendance_app/widgets/field.dart';
import 'package:location_based_attendance_app/widgets/fieldtitle.dart';
import 'package:location_based_attendance_app/widgets/snackbar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  double screenHeight = 0;
  double screenWidth = 0;
  bool isObscure = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  String getAdminEmail() {
    return dotenv.env['ADMIN_EMAIL'] ?? 'admin@gmail.com';
  }

  String getAdminPassword() {
    return dotenv.env['ADMIN_PASSWORD'] ?? '123456';
  }

  Future<void> signin() async {
    if (emailController.text.trim() == getAdminEmail() &&
        passwordController.text == getAdminPassword()) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar().successSnackBar(message: 'Admin Login successfully'),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Adminhomepage()),
      );
      return;
    }

    try {
      await authService.value.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = FirebaseAuth.instance.currentUser;

      if (user != null && !user.emailVerified) {
        await authService.value.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar().errorSnackBar(
            message: "Please verify your email before logging in",
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Verifyemail()),
        );
        return;
      }

      final uid = user!.uid;

      final studentDoc =
          await FirebaseFirestore.instance.collection('Student').doc(uid).get();

      String role = '';
      if (studentDoc.exists) {
        role = 'Student';
      } else if ((await FirebaseFirestore.instance
              .collection('Staff')
              .doc(uid)
              .get())
          .exists) {
        role = 'Staff';
      } else if ((await FirebaseFirestore.instance
              .collection('Admin')
              .doc(uid)
              .get())
          .exists) {
        role = 'Admin';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar().successSnackBar(message: 'Login successfully'),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  role == 'Student'
                      ? Studenthomepage()
                      : role == 'Staff'
                      ? Staffhomepage()
                      : Adminhomepage(),
        ),
      );
    } on FirebaseAuthException {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar().errorSnackBar(message: 'Invalid email or password'),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    final bool isKeyboardVisible = KeyboardVisibilityProvider.isKeyboardVisible(
      context,
    );
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Column(
          children: [
            isKeyboardVisible
                ? SizedBox(height: screenHeight / 16)
                : Container(
                  height: screenHeight / 3,
                  width: screenWidth,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(70),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: screenWidth / 5,
                      color: Colors.white,
                    ),
                  ),
                ),
            barTitle("Login", screenHeight, screenWidth),
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.symmetric(horizontal: screenWidth / 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldTitle("Email", screenWidth),
                  customField(
                    "Enter your email",
                    emailController,
                    Icons.email,
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
                  GestureDetector(
                    onTap: () async {
                      FocusScope.of(context).unfocus();
                      String email = emailController.text.trim();
                      String password = passwordController.text.trim();
        
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          CustomSnackBar().errorSnackBar(
                            message: "Email cannot be empty",
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
                                "Enter your college email in the correct format (student123@college.edu.my)",
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
                        await signin();
                      }
                    },
                    child: buttonInText("LOGIN", screenHeight, screenWidth),
                  ),
                  SizedBox(height: screenHeight * 0.025),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(
                          fontSize: screenWidth * 0.0370,
                          letterSpacing: screenWidth * 0.0018,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Signup()),
                          );
                        },
                        child: Text(
                          'Sign Up',
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
                  SizedBox(height: screenHeight * 0.0005),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Forgotpassword(),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
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
