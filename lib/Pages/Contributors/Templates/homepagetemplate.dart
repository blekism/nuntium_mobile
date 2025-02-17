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
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? lastDocument; // Stores last fetched document for pagination
  bool isLoadingMore = false;
  bool hasMoreTasks = true;
  static const int initialBatchSize = 2; // Start with a small batch size
  int batchSize = initialBatchSize; // Dynamic batch size

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    fetchInitialTasks(); // Load the first batch
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !isLoadingMore &&
        hasMoreTasks) {
      fetchNextBatch();
    }
  }

  Future<void> fetchInitialTasks() async {
    setState(() {
      yourTasksData.clear();
      lastDocument = null;
      hasMoreTasks = true;
      batchSize = initialBatchSize;
    });
    await fetchNextBatch();
  }

  Future<void> fetchNextBatch() async {
    if (!hasMoreTasks || isLoadingMore) return;
    setState(() => isLoadingMore = true);

    Query query = FirebaseFirestore.instance
        .collection('tasks')
        .orderBy('deadline')
        .limit(batchSize);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    QuerySnapshot taskSnapshot = await query.get();
    if (taskSnapshot.docs.isEmpty) {
      setState(() => hasMoreTasks = false);
    } else {
      lastDocument =
          taskSnapshot.docs.last; // Save last document for pagination
    }

    List<Map<String, dynamic>> newTasks = [];

    for (var taskDoc in taskSnapshot.docs) {
      String taskId = taskDoc.id;

      QuerySnapshot assignedTasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .collection('assigned_tasks')
          .where('assignee_id',
              isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .get();

      for (var assignedTaskDoc in assignedTasksSnapshot.docs) {
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
        };
        newTasks.add(combinedTask);
      }
    }

    if (yourTasksData.length < 5) {
      batchSize =
          5; // Load more tasks if there's not enough content on the screen
    }

    setState(() {
      yourTasksData.addAll(newTasks);
      isLoadingMore = false;
    });
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
                const SizedBox(height: 15),
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
            _searchbar(),
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
      height: MediaQuery.of(context).size.height * .05,
      width: double.infinity,
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
    List<Map<String, dynamic>> filteredTasks = selectedSection == 'all'
        ? yourTasksData
        : yourTasksData
            .where((task) => task['status'] == selectedSection)
            .toList();

    return Expanded(
      child: yourTasksData.isEmpty && !isLoadingMore
          ? const Center(child: Text('No tasks found, good job!'))
          : ListView.builder(
              controller: _scrollController,
              itemCount: filteredTasks.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredTasks.length) {
                  return const TaskCardTemplate(isLoading: true);
                }
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
                      isLoading: false,
                    ),
                  ),
                );

                return task['status'] == "assigned"
                    ? Slidable(
                        key: ValueKey(task['title']),
                        endActionPane: ActionPane(
                          motion: const StretchMotion(),
                          dismissible: DismissiblePane(
                            onDismissed: () {
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
                              onPressed: (context) {},
                              backgroundColor: const Color(0XFFD4AF37),
                              foregroundColor: const Color(0xff020B40),
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                child: Text(
                                  'Start',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff020B40),
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

  Widget _buildLoadingList() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: TaskCardTemplate(isLoading: true),
        ),
      ),
    );
  }
}

final List<Map<String, String>> pubSections = [
  {"section": "all"},
  {"section": "assigned"},
  {"section": "ongoing"},
];
