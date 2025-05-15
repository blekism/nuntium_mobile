import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/Eic/create_task_page.dart';
import 'package:nuntium_mobile/Pages/Eic/parent_topic_card.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:nuntium_mobile/models/topic.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class TopicPage extends ConsumerStatefulWidget {
  final String? sectionName;
  final bool secEd;
  final bool shouldShowAppbar;

  const TopicPage({
    super.key,
    this.sectionName,
    this.secEd = false,
    this.shouldShowAppbar = false,
  });

  @override
  ConsumerState<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends ConsumerState<TopicPage> {
  String selectedSection = 'All';

  void filteredSection(String section) {
    setState(() {
      selectedSection = section;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewTopics = ref.watch(topicProvider(widget.sectionName!));

    List<Topic> filteredTopics = [];

    if (viewTopics.hasValue) {
      if (selectedSection == 'All') {
        filteredTopics = viewTopics.value!;
      } else {
        filteredTopics = viewTopics.value!
            .where((topic) => topic.status == selectedSection)
            .toList();
      }
    }

    return Scaffold(
      appBar: widget.shouldShowAppbar == true
          ? CustomAppBar(
              appbarTitle: '${widget.sectionName} Topics',
              hasNavigated: false,
            )
          : null,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 15),
          _genreFilter(),
          const SizedBox(height: 15),
          widget.secEd == true
              ? Container(
                  width: MediaQuery.of(context).size.width * .9,
                  height: MediaQuery.of(context).size.height * .1,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CreateTaskPage(
                                    sectionName: widget.sectionName,
                                  )));
                    },
                    child: DottedBorder(
                      color: const Color(0XFF020B40),
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(10),
                      strokeWidth: 2,
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Create A New Topic'),
                            SizedBox(width: 5),
                            Icon(Icons.add_circle_outline)
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          const SizedBox(height: 15),
          Expanded(
            child: viewTopics.when(
              data: (viewTopics) {
                if (filteredTopics.isEmpty) {
                  return const Center(
                    child: Text('No Topics Found. Start Creating One Now!'),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredTopics.length,
                    itemBuilder: (context, index) {
                      final item = filteredTopics[index];
                      final member1Image = item.members.isNotEmpty
                          ? item.members[0].imageUrl
                          : '';
                      final member2Image = item.members.length > 1
                          ? item.members[1].imageUrl
                          : '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 13),
                        child: ParentTopicCard(
                          id: item.id,
                          topicTitle: item.title,
                          section: item.section,
                          status: item.status,
                          deadline: item.deadline,
                          totalSubtask: item.totalSubtask,
                          completedSubtask: item.completedSubtask,
                          member1: member1Image,
                          member2: member2Image,
                          otherMembers: item.otherMembers,
                          projectStep: item.projectStep,
                        ),
                      );
                    },
                  ),
                );
              },
              error: (error, stack) => Center(child: Text('Error: $error')),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
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
  {"section": "pendingAPR"},
  {"section": "pendingPST"},
  {"section": "To Do"},
  {"section": "Doing"},
];
