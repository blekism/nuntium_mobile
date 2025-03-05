import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:nuntium_mobile/Pages/Contributors/Templates/taskcardtemplate.dart';
import 'package:nuntium_mobile/Pages/SectionEditor/createparenttaskpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignTaskLogPage extends StatefulWidget {
  final String? section;
  const AssignTaskLogPage({super.key, this.section});

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
  String? userSection;

  @override
  void initState() {
    super.initState();
    fetchUserSection();
  }

  Future<void> fetchUserSection() async {
    if (widget.section != null) {
      // if section is passed from eic page
      userSection = widget.section;
    } else {
      // if user is a section editor
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          debugPrint("Fetching data for user: ${user.uid}");

          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            setState(() {
              userSection = userDoc['section'];
            });
            debugPrint("Fetched section: $userSection");
          } else {
            debugPrint("User document does not exist in Firestore.");
          }
        } else {
          debugPrint("No logged-in user found.");
        }
      } catch (e) {
        debugPrint("Error fetching user section: $e");
      }
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
                      builder: (context) =>
                          CreateParentTask(section: userSection),
                      //pupunta na to sa createparenttaskpage
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
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('assigned_by',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid)
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

          List<Map<String, dynamic>> yourTasksData =
              snapshot.data!.docs.map((doc) {
            String documentId = doc.id;
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            return {
              'id': documentId,
              ...data,
            };
          }).toList();

          return ListView.builder(
            itemCount: yourTasksData.length,
            itemBuilder: (context, index) {
              final task = yourTasksData[index];

              return Padding(
                padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
                child: TaskCardTemplate(
                  taskTitle: task['title'],
                  status: task['status'],
                  isParent: task['isParent'],
                  priority: task['priority'],
                  deadline: task['deadline'] is Timestamp
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
          );
        },
      ),
    );
  }
}
