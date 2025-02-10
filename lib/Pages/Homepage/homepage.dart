import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'CardsTemplate/featuredcard.dart';
import 'CardsTemplate/normalpost.dart';
import 'discoverpage.dart';
import 'savedpostspage.dart';
import 'termlypostspage.dart';
import 'readhistory.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final GoogleSignIn _googleSignInLog = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream for featured posts

  bool userIsNew = false;
  int _currentIndex = 0;

  Future<void> _checkNewUser() async {
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
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      await _googleSignInLog.signOut();

      // Sign the user out of Firebase
      // After successful logout, navigate to the login screen:
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (Route<dynamic> route) => false,
        ); // Or your login route
      }
    } catch (e) {
      // Handle logout errors (e.g., show a SnackBar)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error logging out: $e")),
        );
      }
    }
  }

  final List<Widget> _screens = [
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
    const SavedPage(),
    const TermlyPage(),
    const HistoryPage(),
  ];

  @override //this is whats rendered when homepage is called
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      drawer: _drawer(context),
      body: _screens[_currentIndex],
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
      selectedItemColor: Colors.blue,
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

  Drawer _drawer(BuildContext context) {
    return Drawer(
      shadowColor: Colors.black,
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            title: const Text('Profile'),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            title: const Text('Contributor Hunt!'),
            onTap: () {
              Navigator.pushNamed(context, '/joinus');
            },
          ),
          ListTile(
            title: const Text('Logout!'),
            onTap: () {
              _logout();
            },
          ),
        ],
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
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

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> featuredPostData;
    List<Map<String, dynamic>> normalPostData;

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
                Text(
                  'ViewAll',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0XFF020B40),
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
                Text(
                  'ViewAll',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0XFF020B40),
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
