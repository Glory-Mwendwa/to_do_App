import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
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
  Future<TaskItem> uploadMyTask(TaskItem task, List<File> files) async {
    final db = FirebaseFirestore.instance;
    final authController = AuthController.to;
    //Map<String, dynamic> t = task.toJson();
    if (authController.user.value == null) {
      throw "User not found";
    }
    task.uid = authController.user.value!.uid;

    late DocumentReference ref;

    if (task.id == null) {
      ref = db.collection("tasks").doc();
    } else {
      ref = db.collection("tasks").doc(task.id);
    }

    task.id = ref.id;

    List<String> urls = [];
    for (File file in files) {
      String? url = await uploadFile(taskId: task.id!, file: file);
      if (url == null || url.isEmpty) {
        continue;
      }
      urls.add(url);
    }

    if (task.attachments.isEmpty) {
      task.attachments = [];
    }
    task.attachments.addAll(urls);

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

  Future<String?> uploadFile({required String taskId, required File file}) async {
    final storageRef = FirebaseStorage.instanceFor(bucket: "gs://smokeless-todo.firebasestorage.app").ref();

    final String fileName = file.path.split('/').last;
    final taskFolderRef = storageRef.child("tasks/$taskId/$fileName");

    log("Should upload to $taskFolderRef");

    TaskSnapshot snapshot = await taskFolderRef.putFile(file).catchError((e, s) {
      log("There was an error uploading the file. $e\n$s");
      return;
    });

    String? downloadUrl = await snapshot.ref.getDownloadURL().catchError((e, s) {
      log("There was an error getting the download url. $e\n$s");
      return "";
    });
    log("Download url for $fileName: $downloadUrl");

    return downloadUrl;
  }
}
