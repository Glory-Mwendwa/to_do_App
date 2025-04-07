import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:to_do/controllers/auth_controller.dart';
import 'package:to_do/models/task_model.dart';

class FirebaseApis {
  static final db = FirebaseFirestore.instance;
  static Future<TaskItem> uploadMyTask(TaskItem task) async {
    final authController = AuthController.to;
    Map<String, dynamic> t = task.toJson();
    if (authController.user.value == null) {
      throw "User not found";
    }
    task.uid = authController.user.value!.uid;
    DocumentReference ref = db.collection("tasks").doc();
    task.id = ref.id;
    await ref.set(task.toJson(firebaseFormat: true)).then((v) => log("Upload task ${task.id}: ${task.title}"));

    return task;
  }
}
