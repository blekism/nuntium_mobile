import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Contributors/Templates/taskcardtemplate.dart';
import 'package:nuntium_mobile/Pages/Contributors/assignedtaskpage.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:nuntium_mobile/Pages/Contributors/createtaskpage.dart';

class HomePageTemplate extends StatefulWidget {
  const HomePageTemplate({super.key});

  @override
  State<HomePageTemplate> createState() => _HomePageTemplate();
}

class _HomePageTemplate extends State<HomePageTemplate> {
  String selectedSection = 'All';

  final List<Map<String, String>> taskList = [
    {
      "taskid": "001",
      "taskTitle": "Task 1",
      "taskPercent": "0%",
      "status": "Ongoing"
    },
    {
      "taskid": "002",
      "taskTitle": "Task 2",
      "taskPercent": "69%",
      "status": "Assigned"
    },
    {
      "taskid": "003",
      "taskTitle": "Task 360",
      "taskPercent": "0%",
      "status": "Ongoing"
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
      "status": "Ongoing"
    },
  ];

  Future<void> filteredSection(String section) async {
    if (section != 'All') {
      setState(() {
        selectedSection = section;
      });
    } else {
      setState(() {
        selectedSection = 'All';
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
          String sectionName = pubSections[index]['section'] ?? 'All';
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
    List<Map<String, String>> filteredTasks = selectedSection == 'All'
        ? taskList
        : taskList.where((task) => task['status'] == selectedSection).toList();

    return Expanded(
      child: ListView.builder(
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
                taskPercent: task['taskPercent'],
                taskTitle: task['taskTitle'],
                status: task['status'],
              ),
            ),
          );

          // Wrap in Slidable only if status is "Assigned"
          return task['status'] == "Assigned"
              ? Slidable(
                  key: ValueKey(task['taskTitle']),
                  endActionPane: ActionPane(
                    motion: const StretchMotion(),
                    dismissible: DismissiblePane(
                      onDismissed: () {
                        setState(() {
                          taskList.removeWhere(
                              (t) => t['taskid'] == task['taskid']);
                        }); //aalisin pag connected na sadb since di na need mag update ng list
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
                      CustomSlidableAction(
                        onPressed: (context) {
                          // Handle action (e.g., mark as started)
                        },
                        backgroundColor: const Color(0XFFD4AF37),
                        foregroundColor: const Color(0xff020B40),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Text(
                            'Start',
                            style: TextStyle(
                              fontSize: 15, // Custom font size
                              fontWeight: FontWeight.bold,
                              color: Color(0xff020B40), // Ensuring text color
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
      ),
    );
  }
}

final List<Map<String, String>> pubSections = [
  {"section": "All"},
  {"section": "Assigned"},
  {"section": "Ongoing"},
];
