import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:location_based_attendance_app/pages/Global/login.dart';
import 'package:location_based_attendance_app/service/auth_service.dart';
import 'package:location_based_attendance_app/widgets/snackbar.dart';

class Verifyemail extends StatefulWidget {
  const Verifyemail({super.key});

  @override
  State<Verifyemail> createState() => _VerifyemailState();
}

class _VerifyemailState extends State<Verifyemail> {
  bool isEmailVerified = false;
  Timer? timer;
  bool canResendEmail = true;
  int remainingSeconds = 0;
  Timer? cooldownTimer;

  @override
  void initState() {
    super.initState();
    isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!isEmailVerified) {
      // Check email verification status less frequently (every 10 seconds)
      timer = Timer.periodic(const Duration(seconds: 10), (timer) {
        checkEmailVerified();
      });

      // Check initial cooldown status
      updateCooldownStatus();
    }
  }

  Future<void> updateCooldownStatus() async {
    final seconds = await authService.value.getRemainingCooldownSeconds();

    setState(() {
      remainingSeconds = seconds;
      canResendEmail = seconds == 0;
    });

    if (seconds > 0 && cooldownTimer == null) {
      startCooldownTimer();
    }
  }

  void startCooldownTimer() {
    cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          canResendEmail = true;
          cooldownTimer?.cancel();
          cooldownTimer = null;
        }
      });
    });
  }

  Future<void> checkEmailVerified() async {
    // Reload user to get fresh verification status
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (mounted) {
        setState(() {
          isEmailVerified = user?.emailVerified ?? false;
        });
      }

      if (isEmailVerified) {
        timer?.cancel();
      }
    } catch (e) {
      debugPrint("Error checking email verification: $e");
    }
  }

  Future<void> sendVerificationEmail() async {
    final success =
        await authService.value.sendVerificationEmailWithRateLimit();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar().successSnackBar(
          message: "Verification email sent. Please check your inbox.",
        ),
      );
      updateCooldownStatus();
    } else {
      if (remainingSeconds > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar().errorSnackBar(
            message:
                "Please wait ${remainingSeconds}s before requesting again.",
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar().errorSnackBar(
            message: "Couldn't send verification email. Try again later.",
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      isEmailVerified
          ? const KeyboardVisibilityProvider(child: Login())
          : Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.black,
              title: Text(
                'Email Verification',
                style: TextStyle(
                  fontFamily: "NexaBold",
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              centerTitle: false,
              iconTheme: const IconThemeData(color: Colors.white),
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
                  // Replace the ElevatedButton.icon with this code
                  GestureDetector(
                    onTap: canResendEmail ? sendVerificationEmail : null,
                    child: Opacity(
                      opacity: canResendEmail ? 1.0 : 0.6,
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    canResendEmail
                                        ? Icons.email
                                        : Icons.hourglass_bottom,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 12),
                                  Padding(
                                    padding: EdgeInsetsDirectional.only(top: 4.0),
                                    child: Text(
                                      canResendEmail
                                          ? 'Resend Email'
                                          : 'Resend in ${remainingSeconds}s',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontFamily: "NexaBold",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (canResendEmail)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(15),
                                      bottomRight: Radius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder:
                              (_) => const KeyboardVisibilityProvider(
                                child: Login(),
                              ),
                        ),
                      );
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          );
}
