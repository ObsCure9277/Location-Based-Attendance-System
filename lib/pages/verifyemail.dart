import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:location_based_attendance_app/wrapper.dart';

class Verifyemail extends StatefulWidget {
  const Verifyemail({super.key});

  @override
  State<Verifyemail> createState() => _VerifyemailState();
}

class _VerifyemailState extends State<Verifyemail> {
  
  @override
  void initState() {
    sendverifylink();
    super.initState();
  }

  sendverifylink() async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.sendEmailVerification().then((value) => {
      Get.snackbar(
        "Verification Email Sent",
        "Please check your email to verify your account.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        margin: const EdgeInsets.all(30),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      ),
    // ignore: body_might_complete_normally_catch_error
    }).catchError((error) {
      Get.snackbar(
        "Error",
        "Failed to send verification email: $error",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(30),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    });
  }

  reload()async {
    await FirebaseAuth.instance.currentUser!.reload().then((value) => {
      Get.offAll(Wrapper()),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verification"),),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Center(
          child: Text(
                "A verification email has been sent to your email address. Please check your inbox and click the link to verify your account.",
                textAlign: TextAlign.center,
              ),
          ),
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: (() => reload()),
        child: const Icon(Icons.restart_alt_rounded),
      ),
    );
  }
}