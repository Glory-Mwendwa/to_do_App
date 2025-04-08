import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_getx_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:mime/mime.dart';
import 'package:to_do/controllers/tasks_controller.dart';
import 'package:to_do/models/task_model.dart';

class TaskPage extends StatefulWidget {
  final TaskItem importedTask;

  const TaskPage({
    super.key,
    required this.importedTask,
  });

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final taskController = TaskController.to;
  late TextEditingController descriptionController;
  DateTime? newDueDate;
  bool isCompleted = false;
  List<File> selectedFiles = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> pickImage() async {
    List<XFile?> pickedImages = await ImagePicker().pickMultiImage();
    for (var i = 0; i < pickedImages.length; i++) {
      if (pickedImages[i] == null) {
        continue;
      }
      setState(() {
        selectedFiles.add(File(pickedImages[i]!.path));
      });
    }
  }

  Future<void> pickFile() async {
    FilePickerResult? pickedFiles = await FilePicker.platform.pickFiles();
    if (pickedFiles != null) {
      List<File> files = pickedFiles.paths.map((path) => File(path!)).toList();
      setState(() {
        selectedFiles.addAll(files);
      });
    }
  }

  void saveTask(TaskItem task) {
    TaskItem updatedTask = TaskItem(
      id: task.id,
      title: task.title,
      description: descriptionController.text,
      status: task.status,
      createdDate: task.createdDate,
      dueDate: newDueDate ?? task.dueDate,
      uid: task.uid,
    );

    onSave(updatedTask);

    log("Updated task: ${updatedTask.toJson()}");
  }

  void onSave(TaskItem updatedTask) async {
    log("saving task: ${updatedTask.toJson()}");
    int index = taskController.tasks.indexWhere((e) => e.id == updatedTask.id);
    setState(() {
      taskController.tasks[index] = updatedTask;
    });
    await taskController.uploadMyTask(updatedTask, selectedFiles);
    log("Task ${updatedTask.id} saved");
  }

  void deleteTask(String id) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task'),
        content: const Text('Are you sure you want to delete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete) {
      taskController.deleteTask(id);
      Navigator.pop(context);
    }
  }

  void showSelectorModal() {
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
              onPressed: () async {
                log("Should allow adding a photo");
                await pickImage();
                Navigator.pop(context);
              },
              child: const Row(
                children: [
                  Text("Add Photo or Video"),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                log("Should allow adding a file");
                await pickFile();
                Navigator.pop(context);
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
  }

  @override
  Widget build(BuildContext context) {
    return GetX(
        init: TaskController(),
        builder: (_) {
          TaskItem task = taskController.tasks.firstWhere((e) => e.id == widget.importedTask.id);
          descriptionController = TextEditingController(text: task.description);

          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: Text(task.title),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteTask(task.id!),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    title: const Text("Mark as complete/incomplete"),
                    subtitle: Text(task.status == "complete" ? "Task is complete" : "Task is incomplete"),
                    value: task.status == "complete",
                    onChanged: (value) {
                      setState(() {
                        taskController.changeStatus(task.id!, value ?? false);
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
                  if (selectedFiles.isEmpty)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                        Radius.circular(15),
                      ))),
                      onPressed: () {
                        log("Should attach file");
                        showSelectorModal();
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
                      ),
                    ),
                  ...selectedFiles.map((e) {
                    final mimeType = lookupMimeType(e.path);
                    String? fileType = mimeType?.split("/").first;

                    switch (fileType) {
                      case "image":
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: Row(
                            children: [
                              const Spacer(),
                              Image.file(File(e.path)),
                              const Spacer(),
                              IconButton(
                                  onPressed: () {
                                    setState(() {
                                      selectedFiles.removeWhere((e2) => e2.path == e.path);
                                    });
                                  },
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red.shade900,
                                  ))
                            ],
                          ),
                        );

                      case "application":
                      case "audio":
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: Colors.black54),
                          ),
                          child: Row(
                            children: [
                              Text(e.path.split("/").last),
                              const Spacer(),
                              IconButton(
                                  onPressed: () {
                                    setState(() {
                                      selectedFiles.removeWhere((e2) => e2.path == e.path);
                                    });
                                  },
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red.shade900,
                                  ))
                            ],
                          ),
                        );
                      default:
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black54),
                          ),
                          child: const Text("Unsupported File Type"),
                        );
                    }
                  }),

                  // Text("Created Date: ${task.createdDate}"),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  if (selectedFiles.isNotEmpty)
                    SizedBox(
                      width: 25,
                      child: ElevatedButton(
                        onPressed: () {
                          log("Should add another photo or file");
                          showSelectorModal();
                        },
                        child: const Text("Add another Item"),
                      ),
                    ),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        saveTask(task);
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
        });
  }
}
