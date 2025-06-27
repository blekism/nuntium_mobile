import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/Eic/parent_topic_card.dart';
import 'package:nuntium_mobile/Pages/Homepage/searchwidget.dart';
import 'package:nuntium_mobile/models/topic.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class AdminSearchPage extends ConsumerStatefulWidget {
  final String section;
  const AdminSearchPage({
    super.key,
    this.section = 'All',
  });

  @override
  ConsumerState<AdminSearchPage> createState() => _AdminSearchPageState();
}

class _AdminSearchPageState extends ConsumerState<AdminSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  List<Topic> _filterArticles(List<Topic> allArticles) {
    return allArticles.where((article) {
      final titleMatch =
          article.title.toLowerCase().contains(_searchQuery.toLowerCase());

      return titleMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final searchItemsView = ref.watch(searchItemsProvider(widget.section));

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
              ),
              const SizedBox(height: 10),
              searchItemsView.when(
                data: (searchedTopics) {
                  final List<Topic> filteredBySearch =
                      _filterArticles(searchedTopics);

                  if (filteredBySearch.isEmpty) {
                    return const Center(
                      child: Text('No Topics Found!'),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredBySearch.length,
                      itemBuilder: (context, index) {
                        final item = filteredBySearch[index];
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
