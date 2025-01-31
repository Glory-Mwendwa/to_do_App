import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:to_do/model_jsons/task_page.dart';

class ToDoListItem extends StatelessWidget {
  final String id;
  final String title;
  final String? description;
  final String status;
  final String createdDate;
  final String? dueDate;
  final String userId;
  final Function(bool) onStatusChange;
  final Function() onDelete;

  const ToDoListItem({
    super.key,
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.createdDate,
    this.dueDate,
    required this.userId,
    required this.onStatusChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        log("clicked on item $id");
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => TaskPage()));
      },
      leading: Checkbox(
          value: status == "complete",
          onChanged: (val) {
            onStatusChange(val ?? false);
          }),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
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
        description ?? "No Description",
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
