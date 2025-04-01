import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/ContentPage/commentsheetv2.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class ArticlePage extends ConsumerStatefulWidget {
  final String? postId;

  const ArticlePage({
    super.key,
    this.postId,
  });

  @override
  ConsumerState<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends ConsumerState<ArticlePage> {
  final firebaseFunctions = FirebaseFunctions();
  bool isLiked = false;
  bool isBookmarked = false;

  @override
  void initState() {
    super.initState();
    loadPostData();
  }

  Future<void> loadPostData() async {
    if (widget.postId != null) {
      DocumentSnapshot postDoc =
          await firebaseFunctions.checkIfSaved(widget.postId!);

      setState(() {
        isLiked = postDoc['isLiked'] ?? false;
        isBookmarked = postDoc['isSaved'] ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final articleView = ref.watch(postContentProvider(widget.postId!));

    return Scaffold(
      appBar: const CustomAppBar(
        appbarTitle: 'NUVation',
      ),
      body: articleView.when(
        data: (articleView) {
          if (articleView == null) {
            return const Center(
              child: Text('Post Not Found'),
            );
          }

          final datePosted =
              articleView['datePosted'] ?? 'date unknown' as Timestamp;
          final dateString = datePosted.toDate().toString();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTag(context, articleView),
                      _bookmarkBtn(context),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _articleTitle(articleView),
                  const SizedBox(height: 10),
                  _authors(),
                  const SizedBox(height: 5),
                  _publishedAt(dateString),
                  const SizedBox(height: 5),
                  _viewCount(articleView),
                  const SizedBox(height: 20),
                  _articleImage(articleView, context),
                  const SizedBox(height: 10),
                  _credits(),
                  const SizedBox(height: 10),
                  _articleContent(articleView),
                  const SizedBox(height: 10),
                  _divider(context),
                  const SizedBox(height: 10),
                  _userActions(context, articleView),
                  const SizedBox(height: 10),
                  _divider(context),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Align _viewCount(Map<String, dynamic> articleView) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Views: ${articleView['totalViews'].toString()}',
        softWrap: true,
        maxLines: 1,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Container _bookmarkBtn(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * .18,
      height: MediaQuery.of(context).size.width * .12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      child: ElevatedButton(
        onPressed: () async {
          if (FirebaseAuth.instance.currentUser != null) {
            setState(() {
              isBookmarked = !isBookmarked;
            });
            if (isBookmarked) {
              await firebaseFunctions.bookmarkArticle(widget.postId!);
            } else {
              await firebaseFunctions.removeBokmark(widget.postId!);
            }
            print('Bookmark status changed');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please login to bookmark this article'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0XFFF5F5F5),
          elevation: 8,
        ),
        child: isBookmarked
            ? Image.asset(
                'assets/images/bookmarked.png',
                width: 36,
                height: 36,
              )
            : Image.asset(
                'assets/images/bookmarks.png',
                width: 36,
                height: 36,
              ),
      ),
    );
  }

  Row _userActions(
    BuildContext context,
    Map<String, dynamic> articleView,
  ) {
    return Row(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * .1 - 40,
          child: ElevatedButton(
            onPressed: () async {
              if (FirebaseAuth.instance.currentUser != null) {
                setState(() {
                  isLiked = !isLiked;
                });
                if (isLiked) {
                  await firebaseFunctions.likeArticle(widget.postId!);
                } else {
                  await firebaseFunctions.removeLike(widget.postId!);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please login to like this article'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0XFFF5F5F5),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isLiked
                    ? Image.asset(
                        'assets/images/liked.png',
                        width: 24, // Adjusted to proper size
                        height: 24,
                      )
                    : Image.asset(
                        'assets/images/like.png',
                        width: 24, // Adjusted to proper size
                        height: 24,
                      ),
                const SizedBox(width: 8), // Adds spacing between icon and text
                Text(
                  articleView['totalLikes'].toString(),
                  style: const TextStyle(
                    color: Color(0XFF020B40),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        // SizedBox(
        //   // width: 180,
        //   height: MediaQuery.of(context).size.height * .1 - 40,
        //   child: ElevatedButton(
        //     onPressed: () {
        //       print('post shared');
        //     },
        //     style: ElevatedButton.styleFrom(
        //       backgroundColor: const Color(0XFFF5F5F5),
        //       elevation: 4,
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(15),
        //       ),
        //     ),
        //     child: Row(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       children: [
        //         Image.asset(
        //           'assets/images/share.png',
        //           width: 24, // Adjusted to proper size
        //           height: 24,
        //         ),
        //         const SizedBox(width: 8), // Adds spacing between icon and text
        //         const Text(
        //           '20k',
        //           style: TextStyle(
        //             color: Color(0XFF020B40),
        //             fontSize: 16,
        //             fontWeight: FontWeight.w600,
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
        // const SizedBox(width: 14),
        SizedBox(
          // width: 180,
          height: MediaQuery.of(context).size.height * .1 - 40,
          child: ElevatedButton(
            onPressed: FirebaseAuth.instance.currentUser != null
                ? () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      )),
                      builder: (context) =>
                          CommentSheetV2(postId: widget.postId!),
                    );
                  }
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please login to comment'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0XFFF5F5F5),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/comment.png',
                  width: 24, // Adjusted to proper size
                  height: 24,
                ),
                const SizedBox(width: 8), // Adds spacing between icon and text
                Text(
                  articleView['totalComments'].toString(),
                  style: const TextStyle(
                    color: Color(0XFF020B40),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Container _divider(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: MediaQuery.of(context).size.width * .85,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Text _articleContent(Map<String, dynamic> articleView) {
    return Text(
      articleView['content'],
      softWrap: true,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Text _credits() {
    return Text(
      'Credits to photo',
      softWrap: true,
      maxLines: 3,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  ClipRRect _articleImage(
      Map<String, dynamic> articleView, BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        articleView['image'],
        fit: BoxFit.cover,
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width * .8,
        height: MediaQuery.of(context).size.height * .35,
      ),
    );
  }

  Align _publishedAt(String dateString) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Published at $dateString',
        softWrap: true,
        maxLines: 3,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Align _authors() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'By Blakey-kunnie and Hannah Duppybaby',
        softWrap: true,
        maxLines: 3,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Align _articleTitle(Map<String, dynamic> articleView) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        articleView['title'],
        softWrap: true,
        maxLines: 3,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Align _sectionTag(BuildContext context, Map<String, dynamic> articleView) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width * .20,
        decoration: BoxDecoration(
            color: const Color(0XFF020B40),
            borderRadius: BorderRadius.circular(5)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            articleView['section'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
