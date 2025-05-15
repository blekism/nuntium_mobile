import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/Eic/parent_topic_card.dart';
import 'package:nuntium_mobile/Pages/Homepage/searchwidget.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class AdminSearchPage extends ConsumerStatefulWidget {
  const AdminSearchPage({super.key});

  @override
  ConsumerState<AdminSearchPage> createState() => _AdminSearchPageState();
}

class _AdminSearchPageState extends ConsumerState<AdminSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load initial data when the page is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchItemsProvider('All').future);
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchItemsView = ref.watch(searchItemsProvider(
        _searchController.text.isEmpty ? 'All' : _searchController.text));
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SearchWidget(
                searchController: _searchController,
                usedInPage: 'adminsearch',
                onSearch: (value) {
                  setState(() {
                    // Trigger search when the user submits a query
                    ref.refresh(searchItemsProvider(value));
                  });
                },
              ),
              const SizedBox(height: 10),
              searchItemsView.when(
                data: (searchedTopics) {
                  if (searchedTopics.isEmpty) {
                    return const Center(
                      child: Text('No Topics Found. Start Creating One Now!'),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: searchedTopics.length,
                      itemBuilder: (context, index) {
                        final item = searchedTopics[index];
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
            ],
          ),
        ),
      ),
    );
  }
}
