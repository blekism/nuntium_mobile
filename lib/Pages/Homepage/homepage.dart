import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'CardsTemplate/featuredcard.dart';
import 'CardsTemplate/normalpost.dart';
import 'discoverpage.dart';
import 'savedpostspage.dart';
import 'termlypostspage.dart';
import 'readhistory.dart';
import 'package:nuntium_mobile/Pages/appdrawer.dart';

class Homepage extends StatefulWidget {
  final VoidCallback? onLogout;
  final String? userRole;
  const Homepage({
    super.key,
    this.onLogout,
    this.userRole,
  });

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool userIsNew = false;
  int _currentIndex = 0;
  late List<Widget> _screens;

  Future<void> _checkNewUser() async {
    print('user role is ${widget.userRole}');
    User? user = _auth.currentUser;
    if (user != null) {
      final isNewUser =
          user.metadata.creationTime == user.metadata.lastSignInTime;
      print('im home niggas');
      print('creation time uwu: ${user.metadata.creationTime}');
      print('last sign in time: ${user.metadata.lastSignInTime}');

      if (isNewUser) {
        setState(() {
          userIsNew = true;
        });
      } else {
        setState(() {
          userIsNew = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkNewUser();

    _screens = [
      HomeScreen(
        //change yung qquery na posts to most recent lang e.g. 10 most recent
        featuredPost: FirebaseFirestore.instance
            .collection('posts')
            .where('isFeatured', isEqualTo: true)
            .snapshots(),
        normalPost: FirebaseFirestore.instance
            .collection('posts')
            .where('isNormal', isEqualTo: true)
            .snapshots(),
      ),
      const DiscoverPage(),
      SavedPage(
        userRole: widget.userRole ?? 'none',
      ),
      const TermlyPage(),
      HistoryPage(
        userRole: widget.userRole ?? 'none',
      ),
    ];
  }

  @override //this is whats rendered when homepage is called
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF2F2F2),
      appBar: _appBar(context),
      drawer: Appdrawer(
        onLogout: widget.onLogout!,
        userRole: widget.userRole ?? 'none',
        pageOrigin: 'reader',
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _bottomNavbar(),
    );
  }

  BottomNavigationBar _bottomNavbar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      selectedItemColor: const Color(0xFF020B40),
      items: [
        BottomNavigationBarItem(
          icon: Image.asset('assets/images/home.png', width: 35, height: 35),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon:
              Image.asset('assets/images/discover.png', width: 35, height: 35),
          label: 'Discover',
        ),
        BottomNavigationBarItem(
          icon:
              Image.asset('assets/images/bookmarks.png', width: 35, height: 35),
          label: 'Bookmarks',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/images/termly.png', width: 35, height: 35),
          label: 'Termly',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/images/history.png', width: 35, height: 35),
          label: 'History',
        ),
      ],
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      backgroundColor: Color(0xFFF2F2F2),
      actions: [
        GestureDetector(
          onTap: () {
            print('notif clicked');
          },
          child: Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width * 0.2,
            margin: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0XFFF5F5F5),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Image.asset(
              'assets/images/notif.png',
              width: 35,
              height: 35,
            ),
          ),
        ),
      ],
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Stream<QuerySnapshot> featuredPost;
  final Stream<QuerySnapshot> normalPost;

  const HomeScreen({
    super.key,
    required this.featuredPost,
    required this.normalPost,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> featuredPostData;
    List<Map<String, dynamic>> normalPostData;
    User? currentUser = _auth.currentUser;

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Featured',
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                // Text(
                //   'ViewAll',
                //   style: TextStyle(
                //     fontSize: 12,
                //     color: Color(0XFF020B40),
                //     fontWeight: FontWeight.w500,
                //   ),
                // ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
              stream: widget.featuredPost,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: FeaturedPostCard(
                      isLoading: true,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error occurred while loading latest posts'));
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('No data found'));
                }

                featuredPostData =
                    snapshot.data!.docs.map((DocumentSnapshot document) {
                  var data = document.data() as Map<String, dynamic>;
                  data['id'] = document.id; // Store the document ID
                  return data;
                }).toList();
                print('data found in featured: ${featuredPostData.length}');

                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.20,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: featuredPostData.length,
                    itemBuilder: (context, index) {
                      if (!featuredPostData[index].containsKey('isFeatured')) {
                        print('url is ${featuredPostData[index]['image']}');
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: FeaturedPostCard(
                            imageAsset: featuredPostData[index]['image'] ??
                                'assets/images/nudasma.jpg',
                            sectionType:
                                featuredPostData[index]['section'] ?? "unknown",
                            articleTitle:
                                featuredPostData[index]['title'] ?? "unknown",
                            timePosted:
                                featuredPostData[index]['time'] ?? "unknown",
                            postID: featuredPostData[index]['id'],
                            isLoading: true,
                            isAuthenticated: currentUser != null,
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: FeaturedPostCard(
                          imageAsset: featuredPostData[index]['image'] ??
                              'assets/images/nudasma.jpg',
                          sectionType:
                              featuredPostData[index]['section'] ?? "News",
                          articleTitle: featuredPostData[index]['title'] ??
                              "Breaking News!",
                          timePosted:
                              featuredPostData[index]['time'] ?? "2 hours ago",
                          postID: featuredPostData[index]['id'],
                          isLoading: false,
                          isAuthenticated: currentUser != null,
                        ),
                      );
                    },
                  ),
                );
              }),

          const SizedBox(height: 13),
          const Padding(
            padding: EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Latest',
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                // Text(
                //   'ViewAll',
                //   style: TextStyle(
                //     fontSize: 12,
                //     color: Color(0XFF020B40),
                //     fontWeight: FontWeight.w500,
                //   ),
                // ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
              stream: widget.normalPost,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const NormalPostCard(
                    isLoading: true,
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error occurred while loading latest posts'));
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('No data found'));
                }

                normalPostData =
                    snapshot.data!.docs.map((DocumentSnapshot document) {
                  var data = document.data() as Map<String, dynamic>;
                  data['id'] = document.id; // Store the document ID
                  return data;
                }).toList();
                print('data found: ${normalPostData.length}');

                return Expanded(
                  child: ListView.builder(
                    itemCount: normalPostData.length,
                    itemBuilder: (context, index) {
                      if (!normalPostData[index].containsKey('isNormal')) {
                        return Padding(
                          padding: const EdgeInsets.only(
                              left: 16.0, right: 16.0, bottom: 16),
                          child: NormalPostCard(
                            imageAsset: normalPostData[index]['image'] ??
                                'assets/images/nudasma.jpg',
                            sectionType:
                                normalPostData[index]['section'] ?? "unknown",
                            articleTitle:
                                normalPostData[index]['title'] ?? "unknown",
                            datePosted:
                                normalPostData[index]['time'] ?? "unknown",
                            postID: normalPostData[index]['id'],
                            isLoading: true,
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, bottom: 16),
                        child: NormalPostCard(
                          imageAsset: normalPostData[index]['image'] ??
                              'assets/images/nudasma.jpg',
                          sectionType:
                              normalPostData[index]['section'] ?? "News",
                          articleTitle: normalPostData[index]['title'] ??
                              "Breaking News!",
                          datePosted:
                              normalPostData[index]['time'] ?? "2 hours ago",
                          postID: normalPostData[index]['id'],
                          isLoading: false,
                        ),
                      );
                    },
                  ),
                );
              }),
          // userIsNew
          //     ? const Text('Welcome New user!')
          //     : const Text('Welcome Back!'),
        ],
      ),
    );
  }
}
