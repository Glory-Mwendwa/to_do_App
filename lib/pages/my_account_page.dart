import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:to_do/controllers/auth_controller.dart';
import 'package:to_do/controllers/tasks_controller.dart';
import 'package:to_do/theme/styles.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  _MyAccountPageState createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  User? user = FirebaseAuth.instance.currentUser;
  final taskController = TaskController.to;
  final authController = Get.find<AuthController>();
  XFile? profilePhoto;
  bool isChangingProfileImage = false;

  Future<void> changeProfile() async {
    XFile? changedProfile = await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      isChangingProfileImage = true;
    });

    if (changedProfile != null && user != null) {
      File file = File(changedProfile.path);

      String? downloadUrl = await taskController.uploadProfile(userId: user!.uid, file: file);
      if (downloadUrl == null || downloadUrl.isEmpty) {
        log("Download URL is null");
        return;
      }
      await taskController.uploadUserDetails(user!, downloadUrl);

      await user!.updatePhotoURL(downloadUrl);
      await user!.reload();
      user = FirebaseAuth.instance.currentUser;

      log("Profile photo updated successfully!");

      setState(() {
        profilePhoto = changedProfile;
      });
      setState(() {
        isChangingProfileImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Account"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MenuAnchor(
            builder: (context, controller, child) => InkWell(
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              child: isChangingProfileImage
                  ? Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.white,
                      ),
                      child: SpinKitFadingFour(
                        size: 20,
                        color: $styles.colors.accent,
                      ),
                    )
                  : CircleAvatar(
                      radius: 50,
                      backgroundImage: profilePhoto != null
                          ? FileImage(File(profilePhoto!.path))
                          : user?.photoURL != null
                              ? CachedNetworkImageProvider(user!.photoURL!)
                              : null,
                      child:
                          (profilePhoto == null && user?.photoURL == null) ? const Icon(Icons.person, size: 50) : null,
                    ),
            ),
            menuChildren: [
              MenuItemButton(
                onPressed: () {
                  changeProfile();
                },
                child: const Text("Change Photo"),
              ),
              MenuItemButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Remove Photo"),
              ),
            ],
            child: CircleAvatar(
              radius: 50,
              backgroundImage: profilePhoto != null
                  ? FileImage(File(profilePhoto!.path))
                  : user?.photoURL != null
                      ? CachedNetworkImageProvider(user!.photoURL!)
                      : null,
              child: (profilePhoto == null && user?.photoURL == null) ? const Icon(Icons.person, size: 50) : null,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Name: ", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(user?.displayName ?? "No name"),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Email: ", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(user?.email ?? "Not Identified"),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text(
                          "Sign Out",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: const Text(
                          "Are you sure you want to sign out?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              authController.signOut();
                            },
                            child: const Text(
                              "Yes",
                            ),
                          )
                        ],
                      );
                    });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Sign out",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
