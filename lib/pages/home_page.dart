import 'dart:convert';
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:to_do/controllers/auth_controller.dart';
import 'package:to_do/model_jsons/firebase/fire_base_api.dart';
import 'package:to_do/models/task_model.dart';
import 'package:to_do/pages/my_account_page.dart';
import 'package:to_do/widgets/todo_list_item.dart';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? user = FirebaseAuth.instance.currentUser;
  List<Task> toDoItems = [];
  final AuthController authController = Get.find();
  DateTime? pickedDate;
  void initState() {
    super.initState();
    log("Message been initialized");
    loadTasks();
  }

  void loadTasks() async {
    final String jsonString = await rootBundle.loadString('assets/tasks.json');
    final List<dynamic> taskList = json.decode(jsonString);
    log('taskList:$taskList');

    List<Task> tasks = taskList.map((e) => Task.fromMap(e)).toList();

    setState(() {
      toDoItems = tasks;
    });
  }

  void onSave(Task t) {
    log("saving task: ${t.toJson()}");
    int index = toDoItems.indexWhere((e) => e.id == t.id);
    setState(() {
      toDoItems[index] = t;
    });
  }

  void onItemStatusChange(String id, bool val) {
    log("item $id status changed to $val ");
    String newStatus = val ? "complete" : "incomplete";
    int index = toDoItems.indexWhere((e) => e.id == id);
    Task t = toDoItems[index];
    t.status = newStatus;

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

  void onItemDelete(String id) {
    log("item $id deleted ");

    setState(() {
      toDoItems.removeWhere((e) => e.id == id);
    });
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

                          Task savedTask = await FirebaseApis.uploadMyTask(newTask);
                          setState(() {
                            toDoItems.add(savedTask);
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
      body: ListView(
        children: toDoItems
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addNewTask(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
