import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:to_do/controllers/auth_controller.dart';
import 'package:to_do/models/task_model.dart';

class TaskController extends GetxController {
  static TaskController get to => Get.find();

  final tasks = <Task>[].obs;

  @override
  void onInit() async {
    super.onInit();
    tasks.value = await fetchUserTasks();
  }

  //  TODO 1 : Move Uploadtask function here
  Future<Task> uploadMyTask(Task task) async {
    final db = FirebaseFirestore.instance;
    final authController = AuthController.to;
    Map<String, dynamic> t = task.toJson();
    if (authController.user.value == null) {
      throw "User not found";
    }
    task.uid = authController.user.value!.uid;
    DocumentReference ref = db.collection("tasks").doc();
    task.id = ref.id;
    await ref.set(task.toJson(firebaseFormat: true)).then((v) => log("Upload task ${task.id}: ${task.title}"));
    tasks.add(task);

    return task;
  }

  Future<void> deleteTask(String taskId) async {
    final db = FirebaseFirestore.instance;
    await db.collection("tasks").doc(taskId).delete();
    log("Task $taskId deleted successfully");
  }

  Future<void> changeStatus(String taskId, bool val) async {
    final db = FirebaseFirestore.instance;
    String newStatus = val ? "complete" : "incomplete";
    await db.collection("tasks").doc(taskId).update({
      "status": newStatus,
    });
  }

  Future<void> updateTask(Task updatedTask) async {
    await FirebaseFirestore.instance.collection("tasks").doc(updatedTask.id).update({
      "title": updatedTask.title,
      "description": updatedTask.description,
      "status": updatedTask.status,
      "dueDate": updatedTask.dueDate?.toIso8601String(),
      "createdDate": updatedTask.createdDate,
      "id": updatedTask.id,
      "uid": updatedTask.uid,
    });

    log("Task updated successfully in Firestore");
  }

  static Future<List<Task>> fetchUserTasks() async {
    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    List<Task> t = [];
    if (user == null) {
      throw Exception("Cannot fetch docs for anonymous user");
    }
    await db.collection("tasks").where("uid", isEqualTo: user.uid).get().then(
      (querySnapshot) {
        log(user.uid);
        log("Successfully completed: ${querySnapshot.size}");
        t = querySnapshot.docs.map((e) => Task.fromMap(e.data())).toList();
        for (var docSnapshot in querySnapshot.docs) {
          log('${docSnapshot.id} => ${docSnapshot.data()}');
        }
      },
      onError: (e) => log("Error completing: $e"),
    );

    return t;
  }
}
