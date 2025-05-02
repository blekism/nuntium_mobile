import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Homepage/CardsTemplate/featuredcard.dart';
import 'package:nuntium_mobile/Pages/Homepage/searchwidget.dart';
import 'package:nuntium_mobile/models/normalitem.dart';
import 'normalpost.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SeeMorePageTemplate extends StatefulWidget {
  final String pageName;
  final List<NormalItem> shownTopics;
  final List<NormalItem>? termlyFeatured;

  const SeeMorePageTemplate({
    super.key,
    required this.pageName,
    required this.shownTopics,
    this.termlyFeatured,
  });

  @override
  State<SeeMorePageTemplate> createState() => _SeeMorePageTemplateState();
}

class _SeeMorePageTemplateState extends State<SeeMorePageTemplate> {
  String selectedSection = 'All';
  final PageController _pageController = PageController(viewportFraction: 0.9);
  User? currentUser = FirebaseAuth.instance.currentUser;
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

  List<NormalItem> _filterArticles(List<NormalItem> allArticles) {
    return allArticles.where((article) {
      final titleMatch =
          article.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final sectionMatch =
          selectedSection == 'All' || article.section == selectedSection;
      return titleMatch && sectionMatch;
    }).toList();
  }

  Future<void> filteredSection(String section) async {
    if (section != 'All') {
      setState(() {
        selectedSection = section;
      });
    } else {
      setState(() {
        selectedSection = 'All';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<NormalItem> filteredBySearch =
        _filterArticles(widget.shownTopics);

    return Center(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    widget.pageName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          widget.pageName == 'Discover' || widget.pageName == 'Archive'
              ? SearchWidget(
                  searchController: _searchController,
                )
              : const SizedBox.shrink(),
          const SizedBox(height: 15),
          widget.pageName != 'Archive'
              ? _genreFilter()
              : const SizedBox.shrink(),
          const SizedBox(height: 20),
          _mainContent(
            filteredBySearch,
            currentUser,
            widget.termlyFeatured ?? [],
          ),
        ],
      ),
    );
  }

  Expanded _mainContent(
    List<NormalItem> filteredTopics,
    User? currentUser,
    List<NormalItem> termlyFeatured,
  ) {
    switch (widget.pageName) {
      case 'Saved Posts':
      case 'History':
        return _userSavedContent(filteredTopics, currentUser);
      case 'Archive':
        return _termlyBuild(
          _pageController,
          filteredTopics,
          termlyFeatured,
          currentUser,
        );
      default:
        return _discoverBuild(filteredTopics, currentUser);
    }
  }

  Expanded _termlyBuild(
    PageController pageController,
    List<NormalItem> filteredTopics,
    List<NormalItem> termlyFeatured,
    User? currentUser,
  ) {
    return Expanded(
        child: SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * .5,
            child: PageView.builder(
              itemCount: termlyFeatured.length,
              controller: pageController,
              itemBuilder: (context, index) {
                final topic = termlyFeatured[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: FeaturedPostCard(
                    imageAsset: topic.imageUrl[0],
                    sectionType: topic.section,
                    articleTitle: topic.title,
                    postID: topic.id,
                    isAuthenticated: currentUser != null,
                    timePosted: topic.datePosted,
                    isLoading: false,
                    isTermly: true,
                    pdfUrl: topic.pdfUrl,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Additional Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          _genreFilter(),
          const SizedBox(height: 10),
          filteredTopics.isEmpty
              ? const Center(child: Text('No posts available'))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTopics.length,
                  itemBuilder: (context, index) {
                    final topic = filteredTopics[index];
                    return Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, right: 16.0, bottom: 16),
                      child: NormalPostCard(
                        imageAsset: topic.imageUrl[0],
                        sectionType: topic.section,
                        articleTitle: topic.title,
                        postID: topic.id,
                        isAuthenticated: currentUser != null,
                        datePosted: topic.datePosted,
                        isLoading: false,
                        isTermly: true,
                        pdfUrl: topic.pdfUrl,
                      ),
                    );
                  },
                ),
        ],
      ),
    ));
  }

  Expanded _userSavedContent(
      List<NormalItem> filteredTopics, User? currentUser) {
    return Expanded(
      child: filteredTopics.isEmpty
          ? const Center(child: Text('No posts available'))
          : ListView.builder(
              shrinkWrap: true,
              itemCount: filteredTopics.length,
              itemBuilder: (context, index) {
                final topic = filteredTopics[index];

                return Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 16.0, bottom: 16),
                  child: NormalPostCard(
                    imageAsset: topic.imageUrl[0],
                    sectionType: topic.section,
                    articleTitle: topic.title,
                    postID: topic.id,
                    isAuthenticated: currentUser != null,
                    datePosted: topic.datePosted,
                    isLoading: false,
                    isTermly: false,
                  ),
                );
              },
            ),
    );
  }

  Expanded _discoverBuild(List<NormalItem> filteredTopics, User? currentUser) {
    return Expanded(
      child: filteredTopics.isEmpty
          ? const Center(child: Text('No posts available'))
          : ListView.builder(
              shrinkWrap: true,
              itemCount: filteredTopics.length,
              itemBuilder: (context, index) {
                final topic = filteredTopics[index];

                return Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 16.0, bottom: 16),
                  child: NormalPostCard(
                    imageAsset: topic.imageUrl[0],
                    sectionType: topic.section,
                    articleTitle: topic.title,
                    postID: topic.id,
                    isAuthenticated: currentUser != null,
                    datePosted: topic.datePosted,
                    isLoading: false,
                    isTermly: false,
                  ),
                );
              },
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
  {"section": "News"},
  {"section": "Sports"},
  {"section": "Opinion"},
  {"section": "Scitech"},
  {"section": "Feature"},
  {"section": "Literary"},
  {"section": "Photography"},
];

final List<Map<String, String>> termlySections = [
  {"section": "All"},
  {"section": "Magazine"},
  {"section": "Newsletter"},
  {"section": "Literaryfolio"},
];
