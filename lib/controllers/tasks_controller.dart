import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:to_do/controllers/auth_controller.dart';
import 'package:to_do/models/task_model.dart';
import 'package:to_do/utils/show_toast.dart';

class TaskController extends GetxController {
  static TaskController get to => Get.find();

  final isFetchingTasks = false.obs;

  final isUploadingTask = false.obs;

  final tasks = <TaskItem>[].obs;

  @override
  void onInit() async {
    super.onInit();
    tasks.value = await fetchUserTasks();

    // final notificationSettings = await FirebaseMessaging.instance.requestPermission(provisional: true);

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      log("📱 FCM Token: $fcmToken");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'fcmToken': fcmToken}).then((v) {
        log("Updated fcmToken");
      });
    }
    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
          'fcmToken': fcmToken,
        }, SetOptions(merge: true));
      }
      log("🔄 FCM token updated in Firestore: $fcmToken");
    }).onError((err) {
      log("Error catching listener");
    });
  }

  //  TODO 1 : Move Uploadtask function here
  Future<TaskItem> uploadMyTask(TaskItem task, List<File> files) async {
    final db = FirebaseFirestore.instance;
    final authController = AuthController.to;
    //Map<String, dynamic> t = task.toJson();
    if (authController.user.value == null) {
      throw "User not found";
    }

    isUploadingTask.value = true;
    update();

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
      String? downloadUrl = await uploadFile(taskId: task.id!, file: file);
      if (downloadUrl == null || downloadUrl.isEmpty) {
        continue;
      }
      urls.add(downloadUrl);
    }

    if (task.attachments.isEmpty) {
      task.attachments = [];
    }
    task.attachments.addAll(urls);

    await ref.set(task.toJson(firebaseFormat: true)).then((v) {
      log("Upload task ${task.id}: ${task.title}");
      showToast(title: "Task Uploaded Successfully", type: ToastType.success);
      int i = tasks.indexWhere((e) => e.id == task.id);
      if (i > -1) {
        // Task already exists
        tasks[i] = task;
        update();
      } else {
        tasks.add(task);
      }
    });

    isUploadingTask.value = false;
    update();

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
    }).then((v) {
      int i = tasks.indexWhere((t) => t.id == taskId);
      tasks[i].status = newStatus;
      tasks[i] = tasks[i];
    });

    update();
  }

  Future<List<TaskItem>> fetchUserTasks() async {
    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    List<TaskItem> t = [];
    if (user == null) {
      throw Exception("Cannot fetch docs for anonymous user");
    }

    isFetchingTasks.value = true;
    update();

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

    isFetchingTasks.value = false;
    update();

    return t;
  }

  Future<String?> uploadFile({required String taskId, required File file}) async {
    final storageRef = FirebaseStorage.instanceFor(bucket: "gs://smokeless-todo.firebasestorage.app").ref();

    final String fileName = file.path.split('/').last;
    final taskFolderRef = storageRef.child("tasks/$taskId/$fileName");

    log("Should upload to $taskFolderRef");

    try {
      // 1. Upload the file
      TaskSnapshot snapshot = await taskFolderRef.putFile(file);

      // 2. Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      log("Download url for $fileName: $downloadUrl");

      // 3. Return it
      return downloadUrl;
    } catch (e, s) {
      log("There was an error uploading or fetching the URL. $e\n$s");
      return null;
    }
  }

  Future<String?> uploadProfile({required String userId, required File file}) async {
    final storageRef = FirebaseStorage.instanceFor(bucket: "gs://smokeless-todo.firebasestorage.app").ref();

    final String extension = file.path.split('.').last;

    final String fileName = "profile.$extension";

    final profileRef = storageRef.child("img/users/$userId/$fileName");

    log("Should upload to $profileRef");

    try {
      TaskSnapshot snapshot = await profileRef.putFile(file);
      String downloadUrl = await snapshot.ref.getDownloadURL();
      log("Download url for $fileName: $downloadUrl");
      return downloadUrl;
    } catch (e, s) {
      log("There was an error uploading the file. $e\n$s");
      return null;
    }
  }

  Future<void> uploadUserDetails(User user, String downloadUrl) async {
    final db = FirebaseFirestore.instance;

    await FirebaseAuth.instance.currentUser!.updatePhotoURL(downloadUrl);

    DocumentReference ref = db.collection("users").doc(user.uid);

    return await ref.set({
      "uid": user.uid,
      "displayName": user.displayName,
      "email": user.email,
      "photoUrl": downloadUrl,
      "creationTime": user.metadata.creationTime,
    }, SetOptions(merge: true));
  }

  Future<List<File>> downloadTaskFiles({required String taskId}) async {
    final storageRef = FirebaseStorage.instanceFor(bucket: "gs://smokeless-todo.firebasestorage.app").ref();
    final taskFolderRef = storageRef.child("tasks/$taskId");

    List<File> files = [];

    await taskFolderRef.listAll().then((result) async {
      // Log each file in the folder
      for (var item in result.items) {
        log("Item: ${item.name}");
      }
      for (var item in result.items) {
        log("TaskController => Item: ${item.name}");
        // Get the File from the item
        final appDocDir = await getApplicationDocumentsDirectory();
        final filePath = "${appDocDir.absolute}/tasks/$taskId/${item.name}";
        final file = File(filePath);
        files.add(file);
      }
    });

    return files;
  }
}
