import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:to_do/controllers/tasks_controller.dart';
import 'package:to_do/model_jsons/task_page.dart';
import 'package:to_do/models/task_model.dart';

class ToDoListItem extends StatelessWidget {
  final TaskItem task;

  const ToDoListItem({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final taskController = TaskController.to;
    return ListTile(
      onTap: () {
        log("clicked on item ${task.id}");
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => TaskPage(
                    importedTask: task,
                  )),
        );
      },
      leading: Checkbox(
        value: task.status == "complete",
        onChanged: (val) {
          taskController.changeStatus(task.id!, val ?? false);
        },
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Text(
        task.description ?? "No Description",
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      trailing: IconButton(
        onPressed: () {
          taskController.deleteTask(task.id!);
        },
        icon: const Icon(
          Icons.delete,
          color: Colors.red,
        ),
      ),
    );
  }
}
