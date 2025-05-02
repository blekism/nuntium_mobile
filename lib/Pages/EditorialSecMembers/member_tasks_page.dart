import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/Eic/subtask_card.dart';
import 'package:nuntium_mobile/models/taskmodel.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class MemberTasksPage extends ConsumerStatefulWidget {
  final String? uid;

  const MemberTasksPage({
    super.key,
    this.uid,
  });

  @override
  ConsumerState<MemberTasksPage> createState() => _MemberTasksPageState();
}

class _MemberTasksPageState extends ConsumerState<MemberTasksPage> {
  String selectedSection = 'To Do';

  void filteredSection(String section) {
    setState(() {
      selectedSection = section;
    });
  }

  @override
  Widget build(BuildContext context) {
    final memberTasksView = ref.watch(memberTasksProvider(widget.uid!));

    List<TaskModel> filteredTopics = [];

    if (memberTasksView.hasValue) {
      if (selectedSection == 'All') {
        filteredTopics = memberTasksView.value!;
      } else {
        filteredTopics = memberTasksView.value!
            .where((topic) => topic.status == selectedSection)
            .toList();
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              'Welcome Back ${FirebaseAuth.instance.currentUser!.displayName}!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _genreFilter(),
        const SizedBox(height: 10),
        Expanded(
          child: memberTasksView.when(
            data: (memberTask) {
              if (filteredTopics.isEmpty) {
                return const Center(
                  child: Text('No Tasks Yet. Good Job!'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: filteredTopics.length,
                itemBuilder: (context, index) {
                  final item = filteredTopics[index];

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 13),
                      child: SubtaskCard(
                        id: item.id,
                        title: item.title,
                        imageurl: item.assignee,
                        section: item.sectionName,
                        type: item.type,
                        deadline: item.deadline,
                        status: item.status,
                        topicId: item.parentId,
                        sectionId: item.section,
                      ),
                    ),
                  );
                },
              );
            },
            error: (error, stack) => Center(child: Text('Error: $error')),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  SizedBox _genreFilter() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        itemCount: pubSections.length,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
          left: 10,
          right: 10,
        ),
        separatorBuilder: (context, index) => const SizedBox(
          width: 13,
        ),
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
                    ? const Color(0XFF020B40)
                    : const Color(0xffF5F5F5),
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
                      fontWeight: FontWeight.w400,
                      color:
                          isSelected ? const Color(0XFFD4AF37) : Colors.black,
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
}

final List<Map<String, String>> pubSections = [
  {"section": "All"},
  {"section": "To Do"},
  {"section": "Doing"},
  {"section": "Submitted"},
  {"section": "Returned"},
  {"section": "Approved"},
  {"section": "Done"},
];
