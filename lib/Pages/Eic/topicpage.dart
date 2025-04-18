import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/Eic/create_task_page.dart';
import 'package:nuntium_mobile/Pages/Eic/parent_topic_card.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class TopicPage extends ConsumerStatefulWidget {
  final String? sectionID;
  final String? sectionName;
  final bool secEd;

  const TopicPage({
    super.key,
    this.sectionID,
    this.sectionName,
    this.secEd = false,
  });

  @override
  ConsumerState<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends ConsumerState<TopicPage> {
  String selectedSection = 'All';

  @override
  Widget build(BuildContext context) {
    final viewTopics = ref.watch(topicProvider(widget.sectionID!));

    return Scaffold(
      appBar: widget.secEd == true
          ? null
          : CustomAppBar(
              appbarTitle: widget.sectionName,
              hasNavigated: false,
            ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 15),
          Text(
            '${widget.sectionName} Topics',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
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
          const SizedBox(height: 20),
          _genreFilter(),
          const SizedBox(height: 15),
          Container(
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
                              sectionID: widget.sectionID,
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
                  )),
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: viewTopics.when(
              data: (viewTopics) {
                if (viewTopics.isEmpty) {
                  return const Center(
                    child: Text('No Topics Found. Start Creating One Now!'),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: viewTopics.length,
                    itemBuilder: (context, index) {
                      final item = viewTopics[index];
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
                          section: widget.sectionName!,
                          status: item.status,
                          deadline: item.deadline,
                          priority: item.priority,
                          totalSubtask: item.totalSubtask,
                          completedSubtask: item.completedSubtask,
                          member1: member1Image,
                          member2: member2Image,
                          otherMembers: item.otherMembers,
                          projectStep: item.projectStep,
                          sectionId: widget.sectionID!,
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
                  // filteredSection(sectionName);
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
  {"section": "Submitted"},
  {"section": "Done"},
];
