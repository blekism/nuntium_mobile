import 'package:flutter/material.dart';
import 'normalpost.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeeMorePageTemplate extends StatefulWidget {
  final String pageName;
  final Stream<QuerySnapshot> shownContentStream;

  const SeeMorePageTemplate({
    super.key,
    required this.pageName,
    required this.shownContentStream,
  });

  @override
  State<SeeMorePageTemplate> createState() => _SeeMorePageTemplateState();
}

class _SeeMorePageTemplateState extends State<SeeMorePageTemplate> {
  List<Map<String, dynamic>> discoverPostData = [];
  String selectedSection = 'All';
  Map<String, Map<String, dynamic>> _referencedPosts = {};

  Future<List<DocumentSnapshot>> _fetchReferencedPosts(
      List<DocumentReference> postRefs) async {
    List<DocumentSnapshot> fetchedPosts = [];

    for (var ref in postRefs) {
      if (!_referencedPosts.containsKey(ref.id)) {
        DocumentSnapshot snapshot = await ref.get(); // Get post details
        fetchedPosts.add(snapshot);
      }
    }

    return fetchedPosts;
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
          _searchbar(),
          const SizedBox(height: 15),
          _genreFilter(),
          const SizedBox(height: 20),
          _mainContent(),
        ],
      ),
    );
  }

  Expanded _mainContent() {
    return widget.pageName == 'Saved Posts' || widget.pageName == 'History'
        ? Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.shownContentStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingList();
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error occurred while loading latest posts'));
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('No data found'));
                }

                var savedPosts = snapshot.data!.docs;
                var postRefs = savedPosts
                    .map((post) => post['postId'] as DocumentReference)
                    .toList();

                return FutureBuilder<List<DocumentSnapshot>>(
                  future: _fetchReferencedPosts(postRefs),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return _buildLoadingList(); // Show loading UI while fetching
                    }
                    if (futureSnapshot.hasError) {
                      return const Center(
                          child: Text('Error loading referenced posts'));
                    }
                    if (!futureSnapshot.hasData) {
                      return const Center(
                          child: Text('No referenced posts found'));
                    }

                    var referencedPostDocs = futureSnapshot.data!;
                    _referencedPosts.clear();
                    for (var doc in referencedPostDocs) {
                      _referencedPosts[doc.id] =
                          doc.data() as Map<String, dynamic>;
                    }

                    // **Filtering posts before building UI**
                    var filteredPosts = savedPosts.where((post) {
                      var postRef = post['postId'] as DocumentReference;
                      var referencedPost = _referencedPosts[postRef.id];

                      return referencedPost != null &&
                          (selectedSection == 'All' ||
                              referencedPost['section'] == selectedSection);
                    }).toList();

                    return ListView.builder(
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        var postRef =
                            filteredPosts[index]['postId'] as DocumentReference;
                        var referencedPost = _referencedPosts[postRef.id];

                        return Padding(
                          padding: const EdgeInsets.only(
                              left: 16.0, right: 16.0, bottom: 16),
                          child: NormalPostCard(
                            imageAsset: referencedPost?['image'] ??
                                'assets/images/nudasma.jpg',
                            sectionType:
                                referencedPost?['section'] ?? "unknown",
                            articleTitle: referencedPost?['title'] ?? "unknown",
                            datePosted: referencedPost?['time'] ?? "unknown",
                            postID: postRef.id,
                            isLoading: false,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          )
        : Expanded(
            child: StreamBuilder<QuerySnapshot>(
                stream: widget.shownContentStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingList();
                  }
                  if (snapshot.hasError) {
                    return const Center(
                        child:
                            Text('Error occurred while loading latest posts'));
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(child: Text('No data found'));
                  }

                  discoverPostData =
                      snapshot.data!.docs.map((DocumentSnapshot document) {
                    var data = document.data() as Map<String, dynamic>;
                    data['id'] = document.id; // Store the document ID
                    return data;
                  }).toList();
                  print('data found: ${discoverPostData.length}');
                  List<Map<String, dynamic>> filteredPosts = discoverPostData;

                  if (selectedSection != "All") {
                    filteredPosts = discoverPostData
                        .where((post) => post['section'] == selectedSection)
                        .toList();
                  }

                  return ListView.builder(
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, bottom: 16),
                        child: NormalPostCard(
                          imageAsset: filteredPosts[index]['image'] ??
                              'assets/images/nudasma.jpg',
                          sectionType:
                              filteredPosts[index]['section'] ?? "unknown",
                          articleTitle:
                              filteredPosts[index]['title'] ?? "unknown",
                          datePosted: filteredPosts[index]['time'] ?? "unknown",
                          postID: filteredPosts[index]['id'] ?? "0",
                          isLoading: false,
                        ),
                      );
                    },
                  );
                }),
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

  Column _searchbar() {
    return Column(
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
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16),
        child: NormalPostCard(isLoading: true),
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
