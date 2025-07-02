import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:location_based_attendance_app/pages/Global/login.dart';
import 'package:location_based_attendance_app/widgets/snackbar.dart';

class Verifyemail extends StatefulWidget {
  const Verifyemail({super.key});

  @override
  State<Verifyemail> createState() => _VerifyemailState();
}

class _VerifyemailState extends State<Verifyemail> {
  bool isEmailVerified = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    if (!isEmailVerified) {
      sendVerificationEmail();
      timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        checkEmailVerified();
      });
    }
  }

  Future<void> checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      timer?.cancel();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const KeyboardVisibilityProvider(child: Login()),
        ),
      );
    }
    try {
      await user?.reload();
    } catch (e) {
      debugPrint("Error during user,reload(): $e");
      timer?.cancel();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const KeyboardVisibilityProvider(child: Login()),
        ),
      );
      return;
    }

    final refreshedUser = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    setState(() {
      isEmailVerified = refreshedUser?.emailVerified ?? false;
    });

    if (isEmailVerified) {
      timer?.cancel();
    }
  }

  Future<void> sendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser!;

    try {
      await user.sendEmailVerification();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar().errorSnackBar(
          message: "Failed to send verification email: $e",
        ),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      isEmailVerified
          ? const KeyboardVisibilityProvider(child: Login())
          : Scaffold(
            appBar: AppBar(
              title: Text(
                'Email Verification',
                style: TextStyle(
                  fontFamily: "NexaBold",
                  fontSize: 20,
                ),
              ),
              centerTitle: false,
            ),
            body: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'A verification email has been sent to your email',
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: sendVerificationEmail,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.email, size: 30, color: Colors.white),
                    label: const Text('Resent Email', style: TextStyle(fontSize: 22, color: Colors.white)),
                    
                  ),
                ],
              ),
            ),
          );
}
