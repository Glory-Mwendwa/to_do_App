import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:to_do/controllers/auth_controller.dart';
import 'package:to_do/models/task_model.dart';

class TaskController extends GetxController {
  static TaskController get to => Get.find();

  final tasks = <TaskItem>[].obs;

  @override
  void onInit() async {
    super.onInit();
    tasks.value = await fetchUserTasks();
  }

  //  TODO 1 : Move Uploadtask function here
  Future<TaskItem> uploadMyTask(TaskItem task, XFile? image) async {
    final db = FirebaseFirestore.instance;
    final authController = AuthController.to;
    //Map<String, dynamic> t = task.toJson();
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
    await db.collection("tasks").doc(taskId).delete().then((value) {
      tasks.removeWhere((task) => task.id == taskId);
    });
    log("Task $taskId deleted successfully");
  }

  Future<void> changeStatus(String taskId, bool val) async {
    final db = FirebaseFirestore.instance;
    String newStatus = val ? "complete" : "incomplete";
    await db.collection("tasks").doc(taskId).update({
      "status": newStatus,
    });
  }

  Future<void> updateTask(TaskItem updatedTask) async {
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

  static Future<List<TaskItem>> fetchUserTasks() async {
    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    List<TaskItem> t = [];
    if (user == null) {
      throw Exception("Cannot fetch docs for anonymous user");
    }
    await db.collection("tasks").where("uid", isEqualTo: user.uid).get().then(
      (querySnapshot) {
        log(user.uid);
        log("Successfully completed: ${querySnapshot.size}");
        t = querySnapshot.docs.map((e) => TaskItem.fromMap(e.data())).toList();
        for (var docSnapshot in querySnapshot.docs) {
          log('${docSnapshot.id} => ${docSnapshot.data()}');
        }
      },
      onError: (e) => log("Error completing: $e"),
    );

    return t;
  }

  Future<void> uploadFile({required String taskId, required String filePath}) async {
    final storageRef = FirebaseStorage.instanceFor(bucket: "gs://smokeless-todo.firebasestorage.app").ref();

    final fileName = filePath.split('/').last;
    final taskFolderRef = storageRef.child("tasks/$taskId/$fileName");

    await taskFolderRef.putFile(File(filePath)).then((v) {
      log("Upload Successful");
      // ignore: invalid_return_type_for_catch_error
    }).catchError((e, s) => {
          log("Error uploading: $e\n$s"),
        });
  }

  Future<void> fetchFile() async {}
}
