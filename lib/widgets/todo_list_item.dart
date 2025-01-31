import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:to_do/model_jsons/task_page.dart';
import 'package:to_do/models/task_model.dart';

class ToDoListItem extends StatelessWidget {
  final Task task;

  final Function(bool) onStatusChange;
  final Function() onDelete;

  const ToDoListItem({
    super.key,
    required this.task,
    required this.onStatusChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        log("clicked on item $task.id");
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => TaskPage()));
      },
      leading: Checkbox(
          value: task.status == "complete",
          onChanged: (val) {
            onStatusChange(val ?? false);
          }),
      title: Row(
        children: [
          Expanded(
            child: Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              //maxLines: 1,
            ),
          )

          /* Text(
            dueDate ?? "No Due Date",
            style: TextStyle(color: Colors.redAccent),
          ), */
        ],
      ),
      subtitle: Text(
        task.description ?? "No Description",
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      trailing: IconButton(
          onPressed: () => onDelete(),
          icon: Icon(
            Icons.delete,
            color: Colors.red,
          )),
    );
  }
}
