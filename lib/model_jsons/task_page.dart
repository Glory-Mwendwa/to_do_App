import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:to_do/models/task_model.dart';

class TaskPage extends StatefulWidget {
  final Task importedTask;
  final Function(Task) onSave;
  final Function(Task) onDelete;
  final Function(String, bool) onStatusChange;

  const TaskPage({
    super.key,
    required this.importedTask,
    required this.onSave,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  late Task task;
  late TextEditingController descriptionController;
  // DateTime? pickedDate;
  DateTime? newDueDate;
  bool isCompleted = false;

  @override
  void initState() {
    super.initState();
    task = widget.importedTask;
    descriptionController = TextEditingController(text: task.description);
    isCompleted = task.status == "completed";
  }

  void saveTask() {
    Task updatedTask = Task(
      id: task.id,
      title: task.title,
      description: descriptionController.text,
      status: task.status,
      createdDate: task.createdDate,
      dueDate: newDueDate ?? task.dueDate,
      uid: task.uid,
    );

    widget.onSave(updatedTask);
    log("Updated task: ${updatedTask.toJson()}");
  }

  void deleteTask() async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task'),
        content: const Text('Are you sure you want to delete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );

    if (confirmDelete) {
      widget.onDelete(task);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(task.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: deleteTask,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: const Text("Mark as complete/incomplete"),
              subtitle: Text(task.status == "complete" ? "Task is complete" : "Task is incomplete"),
              value: task.status == "complete",
              onChanged: (value) {
                setState(() {
                  widget.onStatusChange(task.id!, value ?? false);
                });
              },
            ),
            const SizedBox(
              height: 16,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Add due date:"),
                  ElevatedButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      setState(() {
                        newDueDate = pickedDate;
                      });
                    },
                    child: const Text("Select Date"),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            TextField(
              maxLines: 5,
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Task Description",
                border: OutlineInputBorder(),
                hintText: "Enter description here...",
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                "Attach file",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            OutlinedButton(
                style: OutlinedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                  Radius.circular(15),
                ))),
                onPressed: () {
                  log("Should attach file");
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 20,
                          ),
                          TextButton(
                            onPressed: () {
                              log("Should allow adding a photo");
                            },
                            child: const Row(
                              children: [
                                Text("Add Photo or Video"),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              log("Should allow adding a file");
                            },
                            child: const Row(
                              children: [
                                Text("Add file"),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Container(
                  alignment: Alignment.center,
                  constraints: const BoxConstraints(
                    minHeight: 140,
                  ),
                  child: Icon(
                    MdiIcons.fileUpload,
                    size: 42,
                  ),
                )),

            // Text("Created Date: ${task.createdDate}"),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  saveTask();
                  Navigator.pop(context);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Save"),
                    SizedBox(width: 8),
                    Icon(Icons.save),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
