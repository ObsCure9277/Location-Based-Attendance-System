import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  // Rate limiting variables
  static const int EMAIL_COOLDOWN_SECONDS = 60; // 1 minute cooldown

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  // Check if email sending is allowed based on last send time
  Future<bool> canSendVerificationEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSentTime = prefs.getInt('last_verification_email_sent');
    
    if (lastSentTime == null) return true;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedSeconds = (now - lastSentTime) ~/ 1000;
    
    return elapsedSeconds >= EMAIL_COOLDOWN_SECONDS;
  }

  // Track when verification email was sent
  Future<void> recordVerificationEmailSent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_verification_email_sent', 
        DateTime.now().millisecondsSinceEpoch);
  }

  // Get remaining time until next email can be sent
  Future<int> getRemainingCooldownSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSentTime = prefs.getInt('last_verification_email_sent');
    
    if (lastSentTime == null) return 0;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedSeconds = (now - lastSentTime) ~/ 1000;
    
    return elapsedSeconds >= EMAIL_COOLDOWN_SECONDS 
        ? 0 
        : EMAIL_COOLDOWN_SECONDS - elapsedSeconds;
  }

  // Add this new method for sending verification emails with rate limiting
  Future<bool> sendVerificationEmailWithRateLimit() async {
    if (currentUser == null) return false;
    
    if (!await canSendVerificationEmail()) {
      return false;
    }
    
    try {
      await currentUser!.sendEmailVerification();
      await recordVerificationEmailSent();
      return true;
    } catch (e) {
      debugPrint("Error sending verification email: $e");
      return false;
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createAccount({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String role,
  }) async {
    UserCredential userCredential = await firebaseAuth
        .createUserWithEmailAndPassword(email: email, password: password);

    String uid = userCredential.user!.uid;

    await firestore
        .collection(
          role == 'Student'
              ? 'Student'
              : (role == 'Staff' ? 'Staff' : 'Admin'),
        )
        .doc(uid)
        .set({
          'id': uid,
          'name': name,
          'email': email,
          'phoneNumber': phoneNumber,
          'role': role,
          'avatar': 'assets/images/userAvatar.png',
          'createdAt': DateTime.now().toIso8601String(),
          'GroupName': '',
        });
    await updateUsername(username: name);

    return userCredential;
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await currentUser!.reauthenticateWithCredential(credential);

      if (currentPassword == newPassword) {
        throw FirebaseAuthException(
          code: 'password-same-as-current',
          message: 'New password cannot be the same as the current password.',
        );
      }
      await currentUser!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('Unknown error: $e');
    }
  }

  Future<void> assignedGroup({
    required String studentEmail,
    required String groupName,
  }) async {
    // Find the student document by email
    final query =
        await firestore
            .collection('Student')
            .where('email', isEqualTo: studentEmail)
            .get();

    if (query.docs.isNotEmpty) {
      final studentDoc = query.docs.first;
      await studentDoc.reference.update({'GroupName': groupName});
    } else {
      throw Exception('Student with email $studentEmail not found.');
    }
  }
}
