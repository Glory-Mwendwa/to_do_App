import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do/widgets/todo_list_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> toDoItems = [];

  @override
  void initState() {
    super.initState();
    initializeToDoItems();
    log("To do Items has been initialized");
  }

  void initializeToDoItems() {
    toDoItems = [
      {
        "id": "1",
        "title": "Flying to Paris",
        "description": "Description 1",
        "status": "complete",
        "createdDate": "24/01",
        "dueDate": null,
        "userId": "100"
      },
      {
        "id": "2",
        "title": "Attend the Board meetings",
        "description": null,
        "status": "complete",
        "createdDate": "24/01",
        "dueDate": null,
        "userId": "100"
      },
      {
        "id": "3",
        "title": "Attend Yoga Classes",
        "description":
            "I need to visit the market and purchase Yoga pants. The classes start early today.",
        "status": "incomplete",
        "createdDate": "24/01",
        "dueDate": "28/01",
        "userId": "100"
      },
      {
        "id": "4",
        "title": "Fold the Laundry",
        "description": "Description 4",
        "status": "complete",
        "createdDate": "24/01",
        "dueDate": null,
        "userId": "100"
      },
      {
        "id": "5",
        "title": "Finish up on reading",
        "description": null,
        "status": "incomplete",
        "createdDate": "24/01",
        "dueDate": "30/01",
        "userId": "100"
      }
    ];
  }

  void onItemStatusChange(String id, bool val) {
    log("item $id status changed to $val ");

    String newStatus = val ? "complete" : "incomplete";
    int index = toDoItems.indexWhere((e) => e["id"] == id);

    if (index != -1) {
      setState(() {
        toDoItems[index]["status"] = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("The task is $newStatus"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void onItemDelete(String id) {
    log("item $id deleted ");

    setState(() {
      toDoItems.removeWhere((e) => e["id"] == id);
    });
  }

  void addNewTask() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final dueDateController = TextEditingController();
    final userIdController = TextEditingController();

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
                //autovalidateMode: AutovalidateMode.always,
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
                        if (value.length > 5) {
                          return "Title cannot exceed 5 characters";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(labelText: "Description"),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Due Date: ${dueDateController.text.isEmpty ? "Not Selected" : dueDateController.text}",
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 365)),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );

                            if (pickedDate != null) {
                              String formattedPickDate =
                                  DateFormat.yMd().format(pickedDate);

                              setModalState(() {
                                dueDateController.text = formattedPickDate;
                              });
                            }
                          },
                          child: const Text("Select Date"),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: userIdController,
                      decoration: const InputDecoration(labelText: "User ID"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          String title = titleController.text.trim();
                          String description =
                              descriptionController.text.trim();
                          String dueDate = dueDateController.text.trim();
                          String userId = userIdController.text.trim();
                          String createdDate =
                              "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

                          setState(() {
                            toDoItems.add({
                              "id": (toDoItems.length + 1).toString(),
                              "title": title,
                              "description":
                                  description.isEmpty ? null : description,
                              "status": "incomplete",
                              "createdDate": createdDate,
                              "dueDate": dueDate.isEmpty ? null : dueDate,
                              "userId": userId,
                            });
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
        title: const Text("Your To Do List"),
      ),
      body: ListView(
        children: toDoItems
            .map(
              (item) => ToDoListItem(
                id: item["id"],
                title: item["title"],
                description: item["description"],
                status: item["status"],
                createdDate: item["createdDate"],
                dueDate: item["dueDate"],
                userId: item["userId"],
                onStatusChange: (bool val) {
                  onItemStatusChange(item["id"], val);
                },
                onDelete: () {
                  onItemDelete(item["id"]);
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
