import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Contributors/Templates/taskcardtemplate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SectionEditorHomePage extends StatefulWidget {
  final String? sectionID;
  final String? sectionName;

  const SectionEditorHomePage({super.key, this.sectionID, this.sectionName});

  @override
  State<SectionEditorHomePage> createState() => _SectionEditorHomePage();
}

class _SectionEditorHomePage extends State<SectionEditorHomePage> {
  String selectedTask = 'all';
  List<Map<String, dynamic>> sectionTaskData = [];
  late Stream<QuerySnapshot> sectionTaskStream;

  @override
  void initState() {
    super.initState();
    sectionTaskStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('section', isEqualTo: widget.sectionID)
        .where('assigned_by', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .orderBy('deadline', descending: true)
        .snapshots();
  }

  Future<void> filteredSection(String section) async {
    if (section != 'all') {
      setState(() {
        selectedTask = section;
      });
    } else {
      setState(() {
        selectedTask = 'all';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
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
            const SizedBox(height: 15),
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
        itemCount: pubTasks.length,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 10, right: 10),
        separatorBuilder: (context, index) => const SizedBox(width: 13),
        itemBuilder: (context, index) {
          String sectionName = pubTasks[index]['section'] ?? 'all';
          bool isSelected = selectedTask == sectionName;
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
                    pubTasks[index]['section'] ?? 'Null',
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
        stream: sectionTaskStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No tasks found, good job!'));
          }

          for (var change in snapshot.data!.docChanges) {
            var data = change.doc.data() as Map<String, dynamic>;
            data['id'] = change.doc.id;

            switch (change.type) {
              case DocumentChangeType.added:
                sectionTaskData.insert(0, data);
                break;
              case DocumentChangeType.modified:
                int index = sectionTaskData
                    .indexWhere((task) => task['id'] == data['id']);
                if (index != -1) {
                  sectionTaskData[index] = data;
                }
                break;
              case DocumentChangeType.removed:
                sectionTaskData.removeWhere((task) => task['id'] == data['id']);
                break;
            }
          }

          List<Map<String, dynamic>> filteredTasks = sectionTaskData;

          if (selectedTask != 'all') {
            filteredTasks = sectionTaskData
                .where((task) => task['status'] == selectedTask)
                .toList();
          }

          return ListView.builder(
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
              return Padding(
                padding: const EdgeInsets.all(6.0),
                child: TaskCardTemplate(
                  taskTitle: task['title'],
                  taskid: task['id'],
                  taskType: widget.sectionName,
                  details: task['details'],
                  isLoading: false,
                  status: task['status'],
                  isParent: task['isParent'],
                  priority: task['priority'],
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

final List<Map<String, String>> pubTasks = [
  {"section": "all"},
  {"section": "created"},
  {"section": "assigned"},
  {"section": "started"},
  {"section": "in progress"},
  {"section": "submitted"},
  {"section": "pendingPST"},
  {"section": "pendingAPR"},
  {"section": "for approval"},
];
