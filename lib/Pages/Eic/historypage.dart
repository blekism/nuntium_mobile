import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/Eic/parent_topic_card.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/models/topic.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class TopicHistoryPage extends ConsumerStatefulWidget {
  final String? sectionName;
  final String? userId;

  const TopicHistoryPage({
    super.key,
    this.sectionName = 'All',
    this.userId,
  });

  @override
  ConsumerState<TopicHistoryPage> createState() => _TopicHistoryPageState();
}

class _TopicHistoryPageState extends ConsumerState<TopicHistoryPage> {
  String selectedSection = 'All';
  User? currentUser = FirebaseAuth.instance.currentUser;

  void _filterBySection(String section) {
    setState(() {
      selectedSection = section;
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyData = ref.watch(historyProvider(widget.sectionName!));

    List<Topic> filteredTopics = [];

    if (historyData.hasValue) {
      if (selectedSection == 'All') {
        filteredTopics = historyData.value!;
      } else {
        filteredTopics = historyData.value!
            .where((topic) => topic.section == selectedSection)
            .toList();
      }
    }

    return Scaffold(
      appBar: widget.userId != null
          ? const CustomAppBar(
              hasNavigated: false,
              appbarTitle: 'History',
            )
          : null,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          widget.sectionName == 'All'
              ? _genreFilter()
              : const SizedBox.shrink(),
          Expanded(
            child: historyData.when(
              data: (historyView) {
                if (filteredTopics.isEmpty) {
                  return const Center(
                    child: Text('No Topics Found. Start Contributing now!'),
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
    // Reusing the genre filter widget structure
    return SizedBox(
      height: 50,
      child: ListView.separated(
        itemCount: pubSections.length, // Use pubSections or a relevant list
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        separatorBuilder: (context, index) => const SizedBox(width: 13),
        itemBuilder: (context, index) {
          String sectionName = pubSections[index]['section'] ?? 'All';
          bool isSelected = selectedSection == sectionName;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isSelected
                    ? const Color(0XFF020B40) // Theme color for selected
                    : const Color(0xffF5F5F5), // Default background
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // Softer shadow
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () {
                  _filterBySection(sectionName); // Use the filtering method
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8), // Adjust padding
                  child: Text(
                    sectionName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500, // Slightly bolder text
                      color: isSelected
                          ? const Color(
                              0XFFD4AF37) // Accent color for selected text
                          : Colors.black87, // Default text color
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
  {"section": "News"},
  {"section": "Sports"},
  {"section": "Opinion"},
  {"section": "Scitech"},
  {"section": "Feature"},
  {"section": "Literary"},
  {"section": "Layout"},
  {"section": "Photojournalism"},
];
