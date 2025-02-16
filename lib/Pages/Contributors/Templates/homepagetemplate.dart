import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Contributors/Templates/taskcardtemplate.dart';
import 'package:nuntium_mobile/Pages/Contributors/assignedtaskpage.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:nuntium_mobile/Pages/Contributors/createtaskpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePageTemplate extends StatefulWidget {
  const HomePageTemplate({super.key});

  @override
  State<HomePageTemplate> createState() => _HomePageTemplate();
}

class _HomePageTemplate extends State<HomePageTemplate> {
  String selectedSection = 'all';
  List<Map<String, dynamic>> yourTasksData = [];

  Stream<List<Map<String, dynamic>>> getUserTasksStream() {
    return FirebaseFirestore.instance
        .collection('tasks') // First, query the tasks collection
        .snapshots()
        .asyncMap((taskSnapshot) async {
      List<Map<String, dynamic>> tasks = [];

      for (var taskDoc in taskSnapshot.docs) {
        String taskId = taskDoc.id;

        // Fetch assigned_tasks subcollection for this task
        QuerySnapshot assignedTasksSnapshot = await FirebaseFirestore.instance
            .collection('tasks')
            .doc(taskId)
            .collection('assigned_tasks')
            .where('assignee_id',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .get();

        for (var assignedTaskDoc in assignedTasksSnapshot.docs) {
          // Combine assigned task & parent task data
          Map<String, dynamic> combinedTask = {
            'taskId': taskId,
            'title': taskDoc['title'],
            'details': taskDoc['details'],
            'deadline': taskDoc['deadline'],
            'priority': taskDoc['priority'],
            'assignee_id': assignedTaskDoc['assignee_id'],
            'assigned_by': taskDoc['assigned_by'],
            'status': assignedTaskDoc['status'],
            'section': taskDoc['section'],
            'task_type': assignedTaskDoc['task_type'],
            // Add additional fields if needed
          };
          tasks.add(combinedTask);
        }
      }

      return tasks; // Return a list of combined task data
    });
  }

  // final List<Map<String, String>> taskList = [
  //   {
  //     "taskid": "001",
  //     "taskTitle": "Task 1",
  //     "taskPercent": "0%",
  //     "status": "Ongoing"
  //   },
  //   {
  //     "taskid": "002",
  //     "taskTitle": "Task 2",
  //     "taskPercent": "69%",
  //     "status": "Assigned"
  //   },
  //   {
  //     "taskid": "003",
  //     "taskTitle": "Task 360",
  //     "taskPercent": "0%",
  //     "status": "Ongoing"
  //   },
  //   {
  //     "taskid": "004",
  //     "taskTitle": "Task 4",
  //     "taskPercent": "50%",
  //     "status": "Assigned"
  //   },
  //   {
  //     "taskid": "005",
  //     "taskTitle": "Task 590",
  //     "taskPercent": "0%",
  //     "status": "Ongoing"
  //   },
  // ];

  Future<void> filteredSection(String section) async {
    if (section != 'all') {
      setState(() {
        selectedSection = section;
      });
    } else {
      setState(() {
        selectedSection = 'all';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Your Tasks',
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssignedTaskPage(
                          taskType: selectedSection,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0XFF020B40),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _genreFilter(),
            const SizedBox(height: 10),
            _cardList(),
          ],
        ),
      ),
    );
  }

  Widget _genreFilter() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        itemCount: pubSections.length,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 10, right: 10),
        separatorBuilder: (context, index) => const SizedBox(width: 13),
        itemBuilder: (context, index) {
          String sectionName = pubSections[index]['section'] ?? 'all';
          bool isSelected = selectedSection == sectionName;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              alignment: Alignment.center,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isSelected
                    ? const Color(0XFFD4AF37)
                    : const Color(0xFF020B40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () {
                  filteredSection(sectionName);
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                      bottom: 4, top: 2, left: 8, right: 8),
                  child: Text(
                    pubSections[index]['section'] ?? 'Null',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color:
                          isSelected ? const Color(0XFF020B40) : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _cardList() {
    return Expanded(
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getUserTasksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // return _buildLoadingList();
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print(snapshot.error);
            return const Center(
                child: Text('Error occurred while loading latest posts'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No task found good job!'));
          }

          yourTasksData = snapshot.data!;

          List<Map<String, dynamic>> filteredTasks = selectedSection == 'all'
              ? snapshot.data!
              : snapshot.data!
                  .where((task) => task['status'] == selectedSection)
                  .toList();

          return ListView.builder(
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final task = filteredTasks[index];

              Widget taskCard = Container(
                width: MediaQuery.of(context).size.width * .90,
                height: MediaQuery.of(context).size.height * .10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: TaskCardTemplate(
                    taskTitle: task['title'],
                    status: task['status'],
                    taskid: task['taskId'],
                    taskType: task['task_type'],
                    details: task['details'],
                  ),
                ),
              );

              // Wrap in Slidable only if status is "Assigned"
              return task['status'] == "assigned"
                  ? Slidable(
                      key: ValueKey(task['title']),
                      endActionPane: ActionPane(
                        motion: const StretchMotion(),
                        dismissible: DismissiblePane(
                          onDismissed: () {
                            // Navigate to CreateTaskPage when fully swiped
                            //create another function to update yung task status here pagka swipe
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateTaskPage(
                                  taskId: task['taskId'],
                                  details: task['details'],
                                  title: task['title'],
                                  taskType: task['task_type'],
                                ),
                              ),
                            );
                          },
                        ),
                        children: [
                          CustomSlidableAction(
                            onPressed: (context) {
                              // Handle action (e.g., mark as started)
                            },
                            backgroundColor: const Color(0XFFD4AF37),
                            foregroundColor: const Color(0xff020B40),
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              child: Text(
                                'Start',
                                style: TextStyle(
                                  fontSize: 15, // Custom font size
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Color(0xff020B40), // Ensuring text color
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      child: taskCard,
                    )
                  : taskCard;
            },
          );
        },
      ),
    );
  }
}

final List<Map<String, String>> pubSections = [
  {"section": "all"},
  {"section": "assigned"},
  {"section": "ongoing"},
];
