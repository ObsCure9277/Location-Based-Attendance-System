import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

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
    required String phoneNumber,
    required String location,
    required String password,
    required String role,
  }) async {
    UserCredential userCredential = await firebaseAuth
        .createUserWithEmailAndPassword(email: email, password: password);

    String uid = userCredential.user!.uid;

    await firestore
        .collection(role == 'student' ? 'Student' : 'Staff')
        .doc(uid)
        .set({
          'name': name,
          'email': email,
          'phoneNumber': phoneNumber,
          'location': location,
          'role': role,
          'avatar': 'assets/images/userAvatar.png',
          'createdAt': DateTime.now().toIso8601String(),
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
          message: 'New password cannot be the same as the current password',
        );
      }
      await currentUser!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw Exception('Unknown error: $e');
    }
  }
}