import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:nuntium_mobile/Pages/SectionEditor/createparenttaskpage.dart';
import 'package:nuntium_mobile/Pages/SectionEditor/Templates/parenttaskcardtemplate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignTaskLogPage extends StatefulWidget {
  const AssignTaskLogPage({super.key});

  @override
  State<AssignTaskLogPage> createState() => _AssignTaskLogPage();
}

class _AssignTaskLogPage extends State<AssignTaskLogPage> {
  final ScrollController _scrollController = ScrollController();
  bool isLoadingMore = false;
  bool hasMoreTasks = true;
  static const int initialBatchSize = 10;
  int batchSize = initialBatchSize;
  DocumentSnapshot? lastDocument;
  List<Map<String, dynamic>> yourTasksData = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    fetchInitialTasks();
    fetchUserSection();
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
        .where('assigned_by',
            isEqualTo: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid))
        .orderBy('deadline', descending: true)
        .limit(batchSize);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    QuerySnapshot taskSnapshot = await query.get();

    if (taskSnapshot.docs.isEmpty) {
      setState(() => hasMoreTasks = false);
    } else {
      lastDocument = taskSnapshot.docs.last;
      print('Last Document: $lastDocument');
    }

    List<Map<String, dynamic>> combinedTasks = [];

    for (final doc in taskSnapshot.docs) {
      String documentId = doc.id;
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      Map<String, dynamic> combinedData = {
        'id': documentId,
        ...data,
      };

      combinedTasks.add(combinedData);
    }

    setState(() {
      yourTasksData.addAll(combinedTasks);
      isLoadingMore = false;
    });
  }

//fetch sec
  String? userSection;

  Future<void> fetchUserSection() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print("Fetching data for user: ${user.uid}");

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userSection = userDoc['section'];
          });
          print("Fetched section: $userSection");
        } else {
          print("User document does not exist in Firestore.");
        }
      } else {
        print("No logged-in user found.");
      }
    } catch (e) {
      print("Error fetching user section: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Tasks',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            DottedBorder(
              color: const Color.fromARGB(255, 116, 116, 116),
              borderType: BorderType.RRect,
              radius: const Radius.circular(10),
              strokeWidth: 1,
              child: GestureDetector(
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateParentTask(
                          section:
                              userSection), //pupunta na to sa createparenttaskpage
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xfff5f5f5),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Create New Task',
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(Icons.add, color: Colors.blueGrey),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _cardList(),
          ],
        ),
      ),
    );
  }

  Widget _cardList() {
    return Expanded(
      child: yourTasksData.isEmpty && !isLoadingMore
          ? const Center(child: Text('No tasks found, Start Creating Now!'))
          : ListView.builder(
              controller: _scrollController,
              itemCount: yourTasksData.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == yourTasksData.length) {
                  return const ParentTaskCardTemplate(isLoading: true);
                }

                final task = yourTasksData[index];

                return Padding(
                  padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
                  child: ParentTaskCardTemplate(
                    taskTitle: task['title'],
                    taskDeadline: task['deadline'] is Timestamp
                        ? (task['deadline'] as Timestamp)
                            .toDate()
                            .toLocal()
                            .toString()
                            .split(' ')[0]
                        : task['deadline'],
                    taskid: task['id'],
                    isLoading: false,
                    section: userSection,
                  ),
                );
              },
            ),
    );
  }
}
