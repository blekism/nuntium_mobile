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
  String selectedTask = 'all';
  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? lastDocument;
  List<Map<String, dynamic>> yourTasksData = [];
  List<String> yourTaskIds = [];
  bool isLoadingMore = false;
  bool hasMoreTasks = true;
  static const int initialBatchSize = 5;
  int batchSize = initialBatchSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    fetchInitialTasks();
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

    // print('section id is ${widget.sectionID}');

    Query query = FirebaseFirestore.instance
        .collection('tasks')
        .where('status',
            isEqualTo: 'ready_post') // Add this line to filter by status
        .orderBy('deadline', descending: true)
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
                'Tasks For Posting',
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
        itemCount: pubSections.length,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 10, right: 10),
        separatorBuilder: (context, index) => const SizedBox(width: 13),
        itemBuilder: (context, index) {
          String sectionName = pubSections[index]['section'] ?? 'all';
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
    List<Map<String, dynamic>> filteredTasks = selectedTask == 'all'
        ? yourTasksData
        : yourTasksData
            .where((task) => task['section'] == selectedTask)
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
                return Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: TaskCardTemplate(
                    taskTitle: task['title'],
                    taskid: task['id'],
                    taskType: widget.sectionName,
                    details: task['details'],
                    isLoading: false,
                    // deadline: task['deadline'],
                    status: task['status'],
                    isParent: task['isParent'],
                  ),
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
  {"section": "News"},
  {"section": "Sports"},
  {"section": "Opinion"},
  {"section": "Layout"},
  {"section": "Feature"},
  {"section": "Literary"},
  {"section": "Photojournalism"},
];
