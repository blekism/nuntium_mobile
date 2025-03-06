import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../Contributors/Templates/taskcardtemplate.dart';

class OrganizationTasks extends StatefulWidget {
  final String? sectionID;
  final String? sectionName;

  const OrganizationTasks({
    super.key,
    this.sectionID,
    this.sectionName,
  });

  @override
  State<OrganizationTasks> createState() => _OrganizationTasksState();
}

class _OrganizationTasksState extends State<OrganizationTasks> {
  String selectedSection = 'all';
  List<Map<String, dynamic>> sectionTaskData = [];
  late Stream<QuerySnapshot> sectionTaskStream;

  @override
  void initState() {
    super.initState();
    print('section id is ${widget.sectionID}');
    sectionTaskStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('section', isEqualTo: widget.sectionID)
        .orderBy('deadline', descending: true)
        .snapshots();
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Organization Tasks',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xff020B40),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Organization Tasks',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _searchbar(),
              const SizedBox(height: 10),
              _genreFilter(),
              const SizedBox(height: 10),
              _cardList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genreFilter() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * .05,
      width: double.infinity,
      child: ListView.separated(
        itemCount: orgTasks.length,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 10, right: 10),
        separatorBuilder: (context, index) => const SizedBox(width: 13),
        itemBuilder: (context, index) {
          String sectionName = orgTasks[index]['section'] ?? 'all';
          bool isSelected = selectedSection == sectionName;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
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
                    orgTasks[index]['section'] ?? 'Null',
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
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('section', isEqualTo: widget.sectionID)
            .orderBy('deadline', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No tasks found, Start Creating Now!'));
          }

          List<Map<String, dynamic>> updatedTasks = [];
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            updatedTasks.add(data);
          }

          // Apply the status filter
          List<Map<String, dynamic>> filteredTasks = updatedTasks;
          if (selectedSection != 'all') {
            filteredTasks = updatedTasks
                .where((task) => task['status'] == selectedSection)
                .toList();
          }

          return ListView.builder(
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final tasks = filteredTasks[index];
              String? deadlineString;

              if (tasks['deadline'] != null) {
                Timestamp deadlineTimestamp = tasks['deadline'] as Timestamp;
                DateTime deadlineDateTime = deadlineTimestamp.toDate();
                deadlineString =
                    DateFormat('yyyy-MM-dd HH:mm').format(deadlineDateTime);
              }

              return Padding(
                padding: const EdgeInsets.all(6.0),
                child: TaskCardTemplate(
                  taskTitle: tasks['title'],
                  taskid: tasks['id'],
                  taskType: widget.sectionName,
                  details: tasks['details'],
                  isLoading: false,
                  deadline: deadlineString,
                  status: tasks['status'],
                  isParent: tasks['isParent'],
                  section: tasks['section'],
                  priority: tasks['priority'],
                  completedTask: tasks['completed_subtasks'],
                  totalTask: tasks['total_subtasks'],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _searchbar() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 15, left: 20, right: 20),
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(
                color: const Color(0xff1D1617).withOpacity(0.11),
                blurRadius: 40,
                spreadRadius: 0.0,
              ),
            ]),
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(15),
                hintText: 'What are you looking for?',
                hintStyle: const TextStyle(
                  color: Color(0xffDDDADA),
                  fontSize: 14,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/images/searchicon.png',
                    height: 25,
                    width: 25,
                  ),
                ),
                suffixIcon: SizedBox(
                  width: 100,
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const VerticalDivider(
                          color: Colors.black,
                          thickness: 0.2,
                          indent: 10,
                          endIndent: 10,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            'assets/images/felter.png',
                            height: 25,
                            width: 25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final List<Map<String, String>> orgTasks = [
  {"section": "all"},
  {"section": "created"},
  {"section": "waiting"},
  {"section": "started"},
  {"section": "in progress"},
  {"section": "submitted"},
  {"section": "pendingPST"},
  {"section": "pendingAPR"},
  {"section": "for approval"},
];
