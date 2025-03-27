import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:to_do/controllers/auth_controller.dart';
import 'package:to_do/controllers/tasks_controller.dart';
import 'package:to_do/models/task_model.dart';
import 'package:to_do/pages/my_account_page.dart';
import 'package:to_do/widgets/todo_list_item.dart';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? user = FirebaseAuth.instance.currentUser;
  final AuthController authController = Get.find();
  DateTime? pickedDate;

  late TaskController taskController;

  void initState() {
    super.initState();
    log("Message been initialized");
    taskController = Get.put(TaskController(), permanent: true);
  }

  void onSave(Task updatedTask) async {
    log("saving task: ${updatedTask.toJson()}");
    int index = taskController.tasks.indexWhere((e) => e.id == updatedTask.id);
    setState(() {
      taskController.tasks[index] = updatedTask;
    });
    await taskController.updateTask(updatedTask);
  }

  void onItemStatusChange(String id, bool val) async {
    log("item $id status changed to $val ");
    String newStatus = val ? "complete" : "incomplete";
    int index = taskController.tasks.indexWhere((e) => e.id == id);
    Task t = taskController.tasks[index];
    t.status = newStatus;

    taskController.changeStatus(id, val);

    if (index != -1) {
      setState(() {
        t.status = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("The task is $newStatus"),
          backgroundColor: newStatus == "complete" ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  void onItemDelete(String taskId) async {
    await taskController.deleteTask(taskId);
    taskController.tasks.removeWhere((task) => task.id == taskId);
  }

  void addNewTask() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final dueDateController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16.0,
            16.0,
            16.0,
            MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: "Title"),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Title cannot be empty";
                        }
                        if (value.length > 50) {
                          return "Title cannot exceed 50 characters";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: "Description"),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Due Date: ${dueDateController.text.isEmpty ? "Not Selected" : dueDateController.text}",
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                          },
                          child: const Text("Select Date"),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          String title = titleController.text.trim();
                          String description = descriptionController.text.trim();
                          DateTime createdDate = DateTime.now();

                          Task newTask = Task(
                            id: Uuid().v4(),
                            title: title,
                            description: description,
                            status: "incomplete",
                            createdDate: createdDate,
                            dueDate: pickedDate,
                          );

                          await taskController.uploadMyTask(newTask);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Task added successfully"),
                              backgroundColor: Colors.green,
                            ),
                          );

                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Add Task"),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hello! ${user?.displayName!.split(" ").first ?? "User"}"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: PopupMenuButton(
              onSelected: (value) {
                if (value == 'My Account') {
                  Get.to(() => MyAccountPage());
                } else if (value == 'logout') {
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
                                Get.offAllNamed('/login'); // Redirect to login page
                              },
                              child: const Text(
                                "Yes",
                              ),
                            )
                          ],
                        );
                      });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'My Account',
                  child: Text("My Account"),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text("Log Out"),
                ),
              ],
              child: CircleAvatar(
                radius: 20,
                backgroundImage: user?.photoURL != null ? CachedNetworkImageProvider(user!.photoURL!) : null,
                child: user?.photoURL == null ? const Icon(Icons.person, size: 20) : null,
              ),
            ),
          ),
        ],
      ),
      body: GetX<TaskController>(
          init: TaskController(),
          builder: (tasksController) {
            return ListView(
              children: tasksController.tasks
                  .map(
                    (item) => ToDoListItem(
                      task: item,
                      onStatusChange: (String id, bool val) {
                        onItemStatusChange(item.id!, val);
                      },
                      onDelete: () {
                        onItemDelete(item.id!);
                      },
                      onSave: (t) {
                        onSave(t);
                      },
                    ),
                  )
                  .toList(),
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addNewTask(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
