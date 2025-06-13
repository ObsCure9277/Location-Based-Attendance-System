import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:location_based_attendance_app/pages/homepage.dart';
import 'package:location_based_attendance_app/widgets/customfield.dart';
import 'package:location_based_attendance_app/widgets/customdropdown.dart';
import 'package:location_based_attendance_app/widgets/fieldtitle.dart';
import 'package:location_based_attendance_app/widgets/snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  String errorMessage = " ";
  bool isLoading = false;
  bool isObscure = true;
  double screenHeight = 0;
  double screenWidth = 0;

  late SharedPreferences sharedPreferences;

  String selectedRole = 'Student';

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = KeyboardVisibilityProvider.isKeyboardVisible(context);
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return isLoading? Center(child: CircularProgressIndicator(),): Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          isKeyboardVisible? SizedBox(height: screenHeight / 16,) : Container(
            height: screenHeight / 3,
            width: screenWidth,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
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
          barTitle(
            selectedRole == "Student" ? "Student Login" : "Staff Login",
            screenHeight,
            screenWidth,
          ),
          Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.symmetric(
              horizontal: screenWidth / 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    fieldTitle("Email", screenWidth),
                    customField(
                      "Enter your email",
                      emailController,
                      false,
                      Icons.email,
                      screenHeight,
                      screenWidth,
                    ),
                    fieldTitle("Password", screenWidth),
                    customField(
                      "Enter your password",
                      passwordController,
                      true,
                      Icons.lock,
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
                    String email = emailController.text.trim();
                    String password = passwordController.text.trim();

                    if (email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        CustomSnackBar().errorSnackBar(message: "Email cannot be empty"),
                      );
                    } else if (password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        CustomSnackBar().errorSnackBar(message: "Password cannot be empty"),
                      );
                    } else if (!RegExp(emailPattern).hasMatch(email)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        CustomSnackBar().errorSnackBar(message: "Enter your college email in the correct format (student123@college.edu.my)"),
                      );
                    } else if (password.isNotEmpty && password.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        CustomSnackBar().errorSnackBar(message: "Password must be at least 6 characters long"),
                      );
                    } else {
                      QuerySnapshot snap = await FirebaseFirestore.instance
                          .collection("Student")
                          .where('studentEmail', isEqualTo: email)
                          .get();
                      
                      try {
                        if(password == snap.docs[0]['studentPassword']) {
                          sharedPreferences = await SharedPreferences.getInstance();

                          await sharedPreferences.setString("studentEmail", email).then((_) {
                            Navigator.pushReplacement(context, 
                              MaterialPageRoute(builder: (context) => Homepage())
                            );
                          });
                          
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            CustomSnackBar().errorSnackBar(message: "Incorrect password"));
                        }
                      } catch (e) {
                        
                        if (e.toString() == "RangeError (index): Index out of range: no indices are valid: 0") {
                          setState(() {
                            errorMessage = "Email not registered";
                          });
                        } else {
                          setState(() {
                            errorMessage = "An error occurred: Please try again later";
                          });
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          CustomSnackBar().errorSnackBar(message: errorMessage));
                      }
                    }
                  },
                  child: Container(
                    height: 60,
                    width: screenWidth,
                    margin: EdgeInsets.only(
                      top: screenHeight / 40,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.all(const Radius.circular(30)),
                    ),
                    child: Center(
                      child: Text(
                        "LOGIN",
                        style: TextStyle(
                          fontSize: screenWidth / 26,
                          color: Colors.white,
                          fontFamily: "Nexabold",
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),  
        ],
      ),
    );
  }

  
  
  
  
}