import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:main/Functions/snackbar.dart';

class FirebaseAuthMethods {
  final FirebaseAuth _auth;
  FirebaseAuthMethods(this._auth);

  User get user => _auth.currentUser!;
  Stream<User?> get authState => FirebaseAuth.instance.authStateChanges();

//Email SignUp

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await sendEmailVerification(context);
      return true;
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message!);
      return false;
    }
  }

  // EMAIL VERIFICATION

  Future<void> sendEmailVerification(BuildContext context) async {
    try {
      _auth.currentUser!.sendEmailVerification();
      showSnackBar(context, 'Email verification sent!');
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message!);
    }
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!user.emailVerified) {
        await sendEmailVerification(context);
      }
      return true;
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message!);
      return false;
    }
  }
}

class FirebaseAuthBinding implements Bindings {
  @override
  void dependencies() {
    Get.put<FirebaseAuthMethods>(FirebaseAuthMethods(FirebaseAuth.instance));
  }
}
