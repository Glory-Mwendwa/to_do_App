import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:to_do/controllers/auth_controller.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.teal,
      body: GetBuilder(
          init: Get.find<AuthController>(),
          builder: (authController) {
            return Center(
              child: authController.isLoadingAuth.value
                  ? const SizedBox(
                      height: 50,
                      width: 50,
                      child: CircularProgressIndicator(),
                    )
                  : SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Column(
                            children: [
                              Text(
                                "Smokeless ToDO",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 24,
                                ),
                              ),
                              Text(
                                "By Glory",
                                style:
                                    TextStyle(fontWeight: FontWeight.w300, fontSize: 12, fontStyle: FontStyle.italic),
                              )
                            ],
                          ),
                          const Spacer(),
                          const Text(
                            "Sign In",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          SignInButton(
                            Buttons.google,
                            onPressed: () async {
                              log("Want to sign in google");

                              authController.signInWithGoogle().then((value) {
                                log("Signed in with Google as ${value.user?.displayName}");
                              }).catchError((error, stacktrace) {
                                log("Error Signing in with Google: $error\n$stacktrace");
                              });
                            },
                          ),
                          const Spacer(),
                          const SizedBox(
                            height: 100,
                          )
                        ],
                      ),
                    ),
            );
          }),
    );
  }
}
