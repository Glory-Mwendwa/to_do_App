import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:to_do/model_jsons/task_page.dart';
import 'package:to_do/models/task_model.dart';

class ToDoListItem extends StatelessWidget {
  final Task task;
  final Function(String, bool) onStatusChange;
  final Function() onDelete;
  final Function(Task) onSave;

  const ToDoListItem({
    super.key,
    required this.task,
    required this.onStatusChange,
    required this.onDelete,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        log("clicked on item ${task.id}");
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => TaskPage(
                    importedTask: task,
                    onSave: (t) => onSave(t),
                    onDelete: (Task) {
                      onDelete();
                    },
                    onStatusChange: (id, val) {
                      onStatusChange(id, val);
                    },
                  )),
        );
      },
      leading: Checkbox(
        value: task.status == "complete",
        onChanged: (val) {
          onStatusChange(task.id!, val ?? false);
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
        onPressed: onDelete,
        icon: const Icon(
          Icons.delete,
          color: Colors.red,
        ),
      ),
    );
  }
}
