import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Contributors/Templates/taskcardtemplate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:nuntium_mobile/Pages/Contributors/createtaskpage.dart';

class AssignedTaskPage extends StatefulWidget {
  final String taskType;

  const AssignedTaskPage({
    super.key,
    required this.taskType,
  });

  @override
  State<AssignedTaskPage> createState() => _AssignedTaskPage();
}

class _AssignedTaskPage extends State<AssignedTaskPage> {
  final List<Map<String, String>> taskList = [
    {
      "taskid": "001",
      "taskTitle": "Task 1",
      "taskPercent": "0%",
      "status": "Assigned"
    },
    {
      "taskid": "002",
      "taskTitle": "Task 2",
      "taskPercent": "69%",
      "status": "Assigned"
    },
    {
      "taskid": "003",
      "taskTitle": "Task 3",
      "taskPercent": "0%",
      "status": "Assigned"
    },
    {
      "taskid": "004",
      "taskTitle": "Task 4",
      "taskPercent": "50%",
      "status": "Assigned"
    },
    {
      "taskid": "005",
      "taskTitle": "Task 590",
      "taskPercent": "0%",
      "status": "Assigned"
    },
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
                  'Assigned Tasks',
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
                    color: widget.taskType == "Assigned"
                        ? const Color(0xA6E4BD3D)
                        : const Color(0xff020B40),
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
                  final task = taskList[index];

                  Widget taskCard = Container(
                    width: MediaQuery.of(context).size.width * .90,
                    height: MediaQuery.of(context).size.height * .10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: TaskCardTemplate(
                        taskPercent: task['taskPercent'],
                        taskTitle: task['taskTitle'],
                        status: widget.taskType,
                        taskid: task['taskid'],
                      ),
                    ),
                  );

                  // Wrap taskCard with Slidable
                  return Slidable(
                    key: ValueKey(task['taskTitle']),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      dismissible: DismissiblePane(
                        onDismissed: () {
                          setState(() {
                            taskList.removeWhere(
                                (t) => t['taskid'] == task['taskid']);
                          });
                          // Navigate to CreateTaskPage when fully swiped
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateTaskPage(
                                taskId: task['taskid'],
                              ),
                            ),
                          );
                        },
                      ),
                      children: [
                        SlidableAction(
                          onPressed: (context) {
                            // Navigate when "Edit" button is tapped
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateTaskPage(
                                  taskId: task['taskid'],
                                ),
                              ),
                            );
                          },
                          backgroundColor: widget.taskType == "Assigned"
                              ? const Color(0XFFD4AF37)
                              : const Color(0xff020B40),
                          foregroundColor: widget.taskType == "Assigned"
                              ? const Color(0xff020B40)
                              : const Color(0XFFD4AF37),
                          borderRadius: BorderRadius.circular(12),
                          label: 'Start Task',
                        ),
                      ],
                    ),
                    child: taskCard,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
