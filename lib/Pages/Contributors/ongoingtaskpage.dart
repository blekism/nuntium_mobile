import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Contributors/Templates/taskcardtemplate.dart';

class OngoingTaskPage extends StatefulWidget {
  const OngoingTaskPage({super.key});

  @override
  State<OngoingTaskPage> createState() => _OngoingTaskPage();
}

class _OngoingTaskPage extends State<OngoingTaskPage> {
  final List<Map<String, String>> taskList = [
    {"taskTitle": "Task 1", "taskPercent": "0%", "status": "Ongoing"},
    {"taskTitle": "Task 2", "taskPercent": "70%", "status": "Ongoing"},
    {"taskTitle": "Task 3", "taskPercent": "0%", "status": "Ongoing"},
    {"taskTitle": "Task 4", "taskPercent": "50%", "status": "Ongoing"},
    {"taskTitle": "Task 5", "taskPercent": "0%", "status": "Ongoing"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ongoing Tasks',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  width: 80,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xff020B40),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Center(
                    child: Text(
                      'Filter',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: taskList.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    child: Container(
                      width: MediaQuery.of(context).size.width * .90,
                      height: MediaQuery.of(context).size.height * .10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TaskCardTemplate(
                          taskPercent: taskList[index]['taskPercent'],
                          taskTitle: taskList[index]['taskTitle'],
                          status: taskList[index]['status'],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
