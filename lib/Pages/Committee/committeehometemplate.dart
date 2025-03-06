import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Contributors/Templates/taskcardtemplate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommitteeHomePageTemplate extends StatefulWidget {
  final String? sectionName;
  const CommitteeHomePageTemplate({super.key, this.sectionName});

  @override
  State<CommitteeHomePageTemplate> createState() =>
      _CommitteeHomePageTemplate();
}

class _CommitteeHomePageTemplate extends State<CommitteeHomePageTemplate> {
  String selectedTask = 'Ready to post Tasks';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // Get screen width
    final titleFontSize = (screenWidth * 0.06).clamp(18.0, 24.0);

    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Tasks For Posting',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: titleFontSize,
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 15),
            _searchbar(),
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
            .where('status', isEqualTo: 'ready_post')
            .orderBy('completed_at', descending: true)
            .snapshots(),
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

          List<Map<String, dynamic>> updatedTasks = [];
          print('Selected Task: $selectedTask'); // ADDED
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            updatedTasks.add(data);
          }

          List<Map<String, dynamic>> filteredTasks = updatedTasks;
          if (selectedTask != 'Ready to post Tasks') {
            filteredTasks = updatedTasks
                .where((task) =>
                    task['section'].toLowerCase() == selectedTask.toLowerCase())
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
