import 'package:flutter/material.dart';
import 'completedtaskitems.dart';

class TaskHistoryPage extends StatelessWidget {
  const TaskHistoryPage({super.key});

  // Sample list of completed tasks
  static final List<Map<String, String>> completedTasks = [
    {
      "title": "Task 1",
      "description": "Assigned to: Blake",
    },
    {
      "title": "Task 2",
      "description": "Assigned to: Hannah",
    },
    {
      "title": "Task 3",
      "description": "Assigned to: Lheorallian",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Completed Tasks'),
      ),
      body: ListView.builder(
        itemCount: completedTasks.length,
        itemBuilder: (context, index) {
          return CompletedItems(
            title: completedTasks[index]["title"] ?? 'No Title',
            description:
                completedTasks[index]["description"] ?? 'No Description',
          );
        },
      ),
    );
  }
}
