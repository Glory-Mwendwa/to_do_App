import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:to_do/pages/home_page.dart';
import 'package:to_do/pages/sign_in_page.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();
  final isLoadingAuth = false.obs;
  final user = FirebaseAuth.instance.currentUser.obs;
  @override
  void onInit() {
    super.onInit();
    FirebaseAuth.instance.authStateChanges().listen((User? u) {
      user.value = u;
      if (u == null) {
        log("User is signed out!");
        isLoadingAuth.value = false;
      } else {
        log("User is signed in!");
        isLoadingAuth.value = false;
        Get.off(() => HomePage());
      }
    });
  }

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    Get.offAll(() => const SignInPage());
  }
}
