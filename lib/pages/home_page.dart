import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:to_do/controllers/auth_controller.dart';
import 'package:to_do/controllers/notification_controller.dart';
import 'package:to_do/controllers/tasks_controller.dart';
import 'package:to_do/model_jsons/task_page.dart';
import 'package:to_do/models/task_model.dart';
import 'package:to_do/pages/my_account_page.dart';
import 'package:to_do/widgets/todo_list_item.dart';

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

  @override
  void initState() {
    super.initState();
    log("Message been initialized");
    taskController = Get.put(TaskController(), permanent: true);
    Get.put(NotificationController(), permanent: true);
  }

  void addNewTask() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

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
                          "Due Date: ${pickedDate == null ? "Not Selected" : DateFormat.yMMMEd().format(pickedDate!)}",
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            setModalState(
                              () {
                                pickedDate = pickedDate;
                              },
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

                          TaskItem newTask = TaskItem(
                            title: title,
                            description: description,
                            status: "incomplete",
                            createdDate: createdDate,
                            dueDate: pickedDate,
                          );

                          await taskController.uploadMyTask(newTask, []).catchError((e, s) {
                            log("There was an error uploading the task. $e\n$s");
                          });

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
                  Get.to(() => const MyAccountPage());
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
            if (tasksController.isFetchingTasks.value) {
              return Center(
                child: SpinKitFadingFour(
                  size: 44,
                  color: Colors.amber.shade700,
                ),
              );
            }
            if (tasksController.tasks.isEmpty) {
              return const Center(
                child: Text(
                  "Nothing yet",
                ),
              );
            }
            return ListView(
              children: tasksController.tasks.map((item) {
                return Slidable(
                  key: ValueKey(item.id ?? item.title + item.createdDate.toString()),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    extentRatio: 0.50,
                    children: [
                      SlidableAction(
                        onPressed: (context) {
                          Get.to(() => TaskPage(importedTask: item));
                        },
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        icon: Icons.edit,
                        label: 'Edit',
                      ),
                      SlidableAction(
                        onPressed: (context) {
                          tasksController.deleteTask(item.id!);
                        },
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Card(
                      color: Colors.red.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: MenuAnchor(
                        menuChildren: [
                          MenuItemButton(
                            onPressed: () async {
                              tasksController.changeStatus(item.id!, item.status != "complete");
                              setState(() {});
                            },
                            child: const Text('Mark complete'),
                          ),
                          MenuItemButton(
                            onPressed: () {
                              Get.to(() => TaskPage(importedTask: item));
                            },
                            child: const Text('Edit'),
                          ),
                          MenuItemButton(
                            onPressed: () {
                              tasksController.deleteTask(item.id!);
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                        builder: (context, controller, child) {
                          return InkWell(
                            onLongPress: () {
                              controller.isOpen ? controller.close() : controller.open();
                            },
                            child: ToDoListItem(task: item),
                          );
                        },
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addNewTask(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
