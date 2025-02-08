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
                  return const Center(child: CircularProgressIndicator());
                  //gawing skeleton loader to
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error occurred while loading latest posts'));
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('No data found'));
                }

                var posts = snapshot.data!.docs;
                print('data found: ${posts.length}');

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    var post = posts[index].data() as Map<String, dynamic>;
                    var postRef = post['postId'] as DocumentReference;

                    return StreamBuilder<DocumentSnapshot>(
                      stream: postRef
                          .snapshots(), // Fetch the data of the referenced post
                      builder: (context, futureSnapshot) {
                        if (futureSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (futureSnapshot.hasError) {
                          return const Center(
                              child: Text('Error loading referenced post'));
                        }

                        var referencedPost =
                            futureSnapshot.data!.data() as Map<String, dynamic>;

                        return Padding(
                          padding: const EdgeInsets.only(
                              left: 16.0, right: 16.0, bottom: 16),
                          child: NormalPostCard(
                            imageAsset: referencedPost['image'] ??
                                'assets/images/nudasma.jpg',
                            sectionType: referencedPost['section'] ?? "News",
                            articleTitle:
                                referencedPost['title'] ?? "Breaking News!",
                            datePosted: referencedPost['time'] ?? "2 hours ago",
                            postID: postRef.id,
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
                    return const Center(child: CircularProgressIndicator());
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

                  return ListView.builder(
                    itemCount: discoverPostData.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, bottom: 16),
                        child: NormalPostCard(
                          imageAsset: discoverPostData[index]['image'] ??
                              'assets/images/nudasma.jpg',
                          sectionType:
                              discoverPostData[index]['section'] ?? "News",
                          articleTitle: discoverPostData[index]['title'] ??
                              "Breaking News!",
                          datePosted:
                              discoverPostData[index]['time'] ?? "2 hours ago",
                          postID: discoverPostData[index]['id'] ?? "0",
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
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              alignment: Alignment.center,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xffF5F5F5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  pubSections[index]['section'] ?? 'Null',
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Color(0XFF515151),
                    fontSize: 14,
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
}

final List<Map<String, String>> pubSections = [
  {"section": "News"},
  {"section": "Sports"},
  {"section": "Entertainment"},
  {"section": "Business"},
  {"section": "Politics"},
  {"section": "Tech"},
  {"section": "Health"},
  {"section": "Science"},
  {"section": "Travel"},
  {"section": "Food"},
  {"section": "Fashion"},
  {"section": "Lifestyle"},
];
