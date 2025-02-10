import 'package:flutter/material.dart';
import '../Homepage/CardsTemplate/normalpost.dart';
import 'commenttemplat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class ContentPage extends StatefulWidget {
  const ContentPage({super.key});

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  bool isLoading = true;
  bool isCommentsLoading = true;
  Map<String, dynamic>? postData;
  String? postid;
  User? user;
  String? userid;
  final _commentController = TextEditingController();
  bool _isTextNotEmpty = false;
  Map<String, String> userCache = {};
  Map<String, Future<String>> userFutures = {};
  List<String> comments = [];
  int _currentIndex = 0;
  double _opacity = 1.0;
  late Timer _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (postid == null) {
      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      postid = args?['postID'];
      if (postid != null) {
        fetchPostData(postid!);
        _fetchComments(postid!);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    final FirebaseAuth commentAuth = FirebaseAuth.instance;
    user = commentAuth.currentUser;
    _commentController.addListener(_updateSendButton);

    if (user != null) {
      userid = user!.uid;
    } else {
      print('User not logged in');
    }

    // Add a listener to detect keyboard visibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _startCommentAnimation() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _opacity = 0.0; // Start fade-out animation
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % comments.length;
            _opacity = 1.0; // Start fade-in animation
          });
        }
      });
    });
  }

  Future<String> getUserName(String userId) async {
    if (userCache.containsKey(userId)) {
      return userCache[userId]!; // Return cached name
    }

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    String userName = userDoc.exists ? userDoc['username'] : 'Unknown';
    userCache[userId] = userName; // Cache the name for future use
    setState(() {
      isCommentsLoading = false;
    });
    return userName;
  }

  void _updateSendButton() {
    setState(() {
      _isTextNotEmpty = _commentController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> insertComment(String comment) async {
    try {
      await FirebaseFirestore.instance.collection('comments').add({
        'comment': comment,
        'postID': postid, // Store post reference
        'userID': userid, // Store user reference
        'time': Timestamp.now(),
      });

      print('Success: Comment added with references');
    } catch (e) {
      print('Error inserting comment: $e');
    }
  }

  Future<void> fetchPostData(String postID) async {
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('posts').doc(postID).get();

    if (doc.exists) {
      setState(() {
        postData = doc.data() as Map<String, dynamic>;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchComments(String postID) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('postID', isEqualTo: postID)
          .orderBy('time', descending: true)
          .get();

      List<String> fetchedComments = snapshot.docs
          .map((doc) =>
              doc['comment'] as String) // Assuming 'text' field in Firestore
          .toList();

      if (fetchedComments.isNotEmpty) {
        setState(() {
          comments = fetchedComments;
        });
        _startCommentAnimation();
      }
    } catch (e) {
      print('Error fetching comments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> postCommentData = [];

    return Scaffold(
      body: SlideContainer(
        postdata: postData,
        isLoading: isLoading,
        commentController: _commentController,
        isTextNotEmpty: _isTextNotEmpty,
        postCommentData: postCommentData,
        getUserName: getUserName,
        userCache: userCache,
        isCommentsLoading: isCommentsLoading,
        userFutures: userFutures,
        currentComment: comments.isNotEmpty ? comments[_currentIndex] : '',
        opacity: _opacity,
        insertComment: () {
          insertComment(_commentController.text);
          _commentController.clear();
        },
        postComments: FirebaseFirestore.instance
            .collection('comments')
            .where('postID', isEqualTo: postid)
            .orderBy('time', descending: true)
            .snapshots(),
      ),
    );
  }
}

class SlideContainer extends StatefulWidget {
  final Map<String, dynamic>? postdata;
  final bool isLoading;
  final TextEditingController commentController;
  final bool isTextNotEmpty;
  final void Function() insertComment;
  final Stream<QuerySnapshot> postComments;
  final List<Map<String, dynamic>> postCommentData;
  final Function(String) getUserName;
  final Map userCache;
  final bool isCommentsLoading;
  final Map<String, Future<String>> userFutures;
  final String currentComment;
  final double opacity;

  const SlideContainer({
    super.key,
    required this.postdata,
    required this.isLoading,
    required this.commentController,
    required this.isTextNotEmpty,
    required this.insertComment,
    required this.postComments,
    required this.postCommentData,
    required this.getUserName,
    required this.userCache,
    required this.isCommentsLoading,
    required this.userFutures,
    required this.currentComment,
    required this.opacity,
  });

  @override
  State<SlideContainer> createState() => _SlideContainerState();
}

class _SlideContainerState extends State<SlideContainer> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
          child: CircularProgressIndicator()); // Show loading spinner
    }
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              widget.postdata?['image'], // Replace with your image
              fit: BoxFit.cover,
            ),
          ),
          _topButtons(context),
          _textOverlay(
            context,
            widget.postdata?['title'],
            widget.postdata?['section'],
            widget.postdata?['time'],
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.4, // 40% of screen upon opening
            minChildSize: 0.4, // 40% of screen
            maxChildSize: 0.83, // 90% of screen
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _textContent(widget.postdata?['content']),
                            const SizedBox(height: 15),
                            _userActions(context),
                            const SizedBox(height: 15),
                            _divider(context),
                            const SizedBox(height: 13),
                            GestureDetector(
                              onTap: () {
                                _showCommentSheet(
                                    context,
                                    widget.commentController,
                                    widget.isTextNotEmpty,
                                    widget.insertComment,
                                    widget.postComments,
                                    widget.postCommentData,
                                    widget.getUserName,
                                    widget.userCache,
                                    widget.isCommentsLoading,
                                    widget.userFutures);
                              },
                              child: _commentSection(
                                context,
                                widget.currentComment,
                                widget.opacity,
                              ),
                            ),
                            const SizedBox(height: 13),
                            _divider(context),
                            const SizedBox(height: 15),
                            const Text(
                              'Related Articles',
                              style: TextStyle(
                                color: Color(0XFF020B40),
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            // _relatedContent()
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
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

  Positioned _textOverlay(BuildContext context, String title, section, time) {
    return Positioned(
      left: 20,
      top: MediaQuery.of(context).size.height * 0.38, // Adjust to align
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0XFF020B40),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.grey,
                  blurRadius: 5.0,
                  spreadRadius: 0.0,
                  offset: Offset(1.0, 1.0),
                ),
              ],
            ),
            child: Text(
              section,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Roboto Slab'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'By DuppyBaby',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Positioned _topButtons(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.1 - 40,
      left: 38,
      right: 38,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * .18,
            height: MediaQuery.of(context).size.width * .12,
            child: ElevatedButton(
              onPressed: () {
                print('pabalik na ko from content');
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0XFFF5F5F5),
                elevation: 8,
              ),
              child: Image.asset(
                'assets/images/back.png',
                width: 36,
                height: 36,
              ),
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * .18,
            height: MediaQuery.of(context).size.width * .12,
            child: ElevatedButton(
              onPressed: () {
                print('kinissmoqohhh');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0XFFF5F5F5),
                elevation: 8,
              ),
              child: Image.asset(
                'assets/images/bookmarks.png',
                width: 36,
                height: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ListView _relatedContent() {
  //   return ListView.builder(
  //     itemCount: normalPosts.length,
  //     physics: const NeverScrollableScrollPhysics(),
  //     shrinkWrap: true,
  //     itemBuilder: (context, index) {
  //       return Padding(
  //         padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16),
  //         child: NormalPostCard(
  //           imageAsset:
  //               normalPosts[index]['image'] ?? 'assets/images/dababy.jpg',
  //           sectionType: normalPosts[index]['section'] ?? "None",
  //           articleTitle: normalPosts[index]['title'] ?? "Untitled",
  //           datePosted: normalPosts[index]['datePosted'] ?? "Unknown Date",
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _commentSection(
      BuildContext context, String currentComment, double opacity) {
    return Center(
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * .2 - 80,
            width: MediaQuery.of(context).size.width * .75,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: const Color.fromARGB(255, 240, 216, 138),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Comments',
                        style: TextStyle(
                          color: Color(0XFF020B40),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 14),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              'assets/images/nudasma.jpg',
                              width: 35,
                              height: 35,
                            ),
                          ),
                          const SizedBox(width: 13),
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity: opacity,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * .5,
                              child: Text(
                                currentComment,
                                style: const TextStyle(
                                  color: Color(0XFF020B40),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Image.asset(
                        'assets/images/forward.png',
                        width: 35,
                        height: 35,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentSheet(
      BuildContext context,
      TextEditingController commentController,
      bool isTextNotEmpty,
      VoidCallback insertComment,
      Stream<QuerySnapshot> postComments,
      List<Map<String, dynamic>> postCommentsData,
      Function getUserName,
      Map userCache,
      bool isCommentsLoading,
      Map<String, Future<String>> userFutures) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
          commentController.addListener(() {
            setModalState(() {
              isTextNotEmpty = commentController.text.trim().isNotEmpty;
            });
          });

          return Stack(
            children: [
              FractionallySizedBox(
                heightFactor: 0.75,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            StreamBuilder(
                              stream: postComments,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return const Center(
                                    child: Text('An error occurred'),
                                  );
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data == null) {
                                  return const Center(
                                    child: Text('No comments found'),
                                  );
                                }

                                postCommentsData = snapshot.data!.docs
                                    .map((DocumentSnapshot document) {
                                  var data =
                                      document.data() as Map<String, dynamic>;
                                  data['id'] =
                                      document.id; // Store the document ID
                                  return data;
                                }).toList();

                                return ListView.builder(
                                  shrinkWrap: true, // Allow the list to shrink
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: postCommentsData.length,
                                  itemBuilder: (context, index) {
                                    String userid =
                                        postCommentsData[index]['userID'];

                                    if (!userFutures.containsKey(userid)) {
                                      userFutures[userid] = getUserName(userid);
                                    }

                                    return FutureBuilder(
                                        future: userFutures[userid],
                                        builder: (context, userSnapshot) {
                                          if (userSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return CommentTemplate(
                                              profilePic:
                                                  'assets/images/nudasma.jpg',
                                              comment: postCommentsData[index]
                                                  ['comment'],
                                              commenter: "Loading...",
                                              isLoading:
                                                  true, // Placeholder while fetching
                                            );
                                          }
                                          if (userCache.containsKey(userid)) {
                                            return CommentTemplate(
                                              profilePic:
                                                  'assets/images/nudasma.jpg',
                                              comment: postCommentsData[index]
                                                  ['comment'],
                                              commenter: userCache[userid]!,
                                              isLoading: false,
                                            );
                                          }

                                          return CommentTemplate(
                                            profilePic:
                                                'assets/images/nudasma.jpg',
                                            comment: postCommentsData[index]
                                                ['comment'],
                                            commenter:
                                                userSnapshot.data.toString(),
                                            isLoading: false,
                                          );
                                        });
                                  },
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context)
                              .viewInsets
                              .bottom, // Adjust based on keyboard
                          left: 8,
                          right: 8,
                          top: 10,
                        ),
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.send,
                                  color: widget.isTextNotEmpty
                                      ? Colors.blue
                                      : Colors.grey),
                              onPressed: widget.isTextNotEmpty
                                  ? () async {
                                      // Call function to send comment
                                      insertComment();
                                    }
                                  : null, // Disable button if text is empty
                            ),
                          ),

                          keyboardType: TextInputType.multiline,
                          maxLines: null, // Allow multiple lines if needed
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        });
      },
    );
  }

  Row _userActions(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * .1 - 40,
          child: ElevatedButton(
            onPressed: () {
              print('post liked');
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
                  'assets/images/like.png',
                  width: 24, // Adjusted to proper size
                  height: 24,
                ),
                const SizedBox(width: 8), // Adds spacing between icon and text
                const Text(
                  '20k',
                  style: TextStyle(
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
        SizedBox(
          // width: 180,
          height: MediaQuery.of(context).size.height * .1 - 40,
          child: ElevatedButton(
            onPressed: () {
              print('post shared');
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
                  'assets/images/share.png',
                  width: 24, // Adjusted to proper size
                  height: 24,
                ),
                const SizedBox(width: 8), // Adds spacing between icon and text
                const Text(
                  '20k',
                  style: TextStyle(
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

  Text _textContent(String content) {
    return Text(
      content,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
