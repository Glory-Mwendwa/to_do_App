import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:to_do/controllers/auth_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:to_do/controllers/tasks_controller.dart';
import 'package:to_do/pages/sign_in_page.dart';
import 'package:to_do/theme/theme.dart';
import 'package:toastification/toastification.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const ToDoApp());
}

class ToDoApp extends StatelessWidget {
  const ToDoApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Get.put(AuthController());
    Get.put(TaskController());
    return ToastificationWrapper(
      child: GetMaterialApp(
        title: 'Smokeless-to-do',
        theme: lightTheme,
        darkTheme: darkTheme,
        home: const SignInPage(),
      ),
    );
  }
}
