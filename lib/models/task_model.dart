import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String? id;
  String title;
  String? description;
  String status;
  DateTime createdDate;
  DateTime? dueDate;
  String? uid;

  Task({
    this.id,
    required this.title,
    this.description,
    required this.status,
    required this.createdDate,
    this.dueDate,
    this.uid,
  });

  factory Task.fromMap(Map<String, dynamic> json) {
    return Task(
        id: json["id"],
        title: json["title"],
        description: json["description"],
        status: json["status"],
        createdDate: DateTime.parse(json["createdDate"]),
        dueDate: json["dueDate"] == null ? null : DateTime.tryParse(json["dueDate"]),
        uid: json["userId"]);
  }

  Map<String, dynamic> toJson({bool firebaseFormat = false}) {
    return {
      "id": id,
      "title": title,
      "description": description,
      "status": status,
      "createdDate": firebaseFormat ? Timestamp.fromDate(createdDate) : createdDate.toIso8601String(),
      "dueDate": firebaseFormat
          ? dueDate == null
              ? null
              : Timestamp.fromDate(dueDate!)
          : dueDate?.toIso8601String(),
      "uid": uid,
    };
  }
}
