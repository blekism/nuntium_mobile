import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Contributors/Templates/taskcardtemplate.dart';
import 'package:nuntium_mobile/Pages/Contributors/assignedtaskpage.dart';
import 'package:nuntium_mobile/Pages/Contributors/ongoingtaskpage.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class HomePageTemplate extends StatefulWidget {
  const HomePageTemplate({super.key});

  @override
  State<HomePageTemplate> createState() => _HomePageTemplate();
}

class _HomePageTemplate extends State<HomePageTemplate> {
  String selectedSection = 'All';

  final List<Map<String, String>> taskList = [
    {"taskTitle": "Task 1", "taskPercent": "0%", "status": "Assigned"},
    {"taskTitle": "Task 2", "taskPercent": "70%", "status": "Ongoing"},
    {"taskTitle": "Task 3", "taskPercent": "0%", "status": "Assigned"},
    {"taskTitle": "Task 4", "taskPercent": "50%", "status": "Ongoing"},
    {"taskTitle": "Task 5", "taskPercent": "0%", "status": "Assigned"},
  ];

  void filteredSection(String section) {
    setState(() {
      selectedSection = section;
    });
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
                    if (selectedSection == "Assigned") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AssignedTaskPage(),
                        ),
                      );
                    } else if (selectedSection == "Ongoing") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OngoingTaskPage(),
                        ),
                      );
                    }
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
