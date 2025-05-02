import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/ContentPage/articlepage.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';
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
  final firebaseFunctions = FirebaseFunctions();

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

  void _handleMessageNavigation(RemoteMessage message) {
    final articleId = message.data['articleId'];
    if (articleId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArticlePage(
            postId: articleId,
          ),
        ),
      );
    }
  }

  void _navigateToIndex(int index) {
    // Keep the general function if needed elsewhere
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();

    // When user taps a notification from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageNavigation(message);
    });

    // When app is launched from terminated via notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessageNavigation(message);
      }
    });

    if (_auth.currentUser != null) {
      firebaseFunctions.resetExpiredLikeThrottles();
      firebaseFunctions.resetExpiredBookmarkThrottles();
    }

    _checkNewUser();

    _screens = [
      HomeScreen(onNavigate: () => _navigateToIndex(1)),
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
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: const CustomAppBar(
        appbarTitle: 'Home',
        hasNavigated: false,
      ),
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
}

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final featuredCards = ref.watch(featuredCardProvider);
    final normalCards = ref.watch(normalCardProvider);
    User? currentUser = _auth.currentUser;
    final screenHeight = MediaQuery.of(context).size.height;
    final pageViewHeight = screenHeight * 0.35;

    return Center(
      child: SingleChildScrollView(
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
                ],
              ),
            ),
            SizedBox(
              height: pageViewHeight,
              child: featuredCards.when(
                data: (featuredCards) {
                  if (featuredCards.isEmpty) {
                    return const Center(
                        child: Text('No featured items available'));
                  }
                  return PageView.builder(
                      controller: _pageController,
                      itemCount: featuredCards.length,
                      itemBuilder: (context, index) {
                        final item = featuredCards[index];

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: FeaturedPostCard(
                            imageAsset: item.imageUrl[0],
                            sectionType: item.section,
                            articleTitle: item.title,
                            postID: item.id,
                            isAuthenticated: currentUser != null,
                            timePosted: item.datePosted,
                            isLoading: false,
                            isTermly: false,
                          ),
                        );
                      });
                },
                loading: () => FeaturedPostCard(
                  isLoading: true,
                  isTermly: false,
                ),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),

            const SizedBox(height: 13),
            const Padding(
              padding: EdgeInsets.all(15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Latest',
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            normalCards.when(
              data: (normalCards) {
                if (normalCards.isEmpty) {
                  return const Center(child: Text('No normal items available'));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: normalCards.length,
                  itemBuilder: (context, index) {
                    final item = normalCards[index];
                    return Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, right: 16.0, bottom: 16),
                      child: NormalPostCard(
                        imageAsset: item.imageUrl[0],
                        sectionType: item.section,
                        articleTitle: item.title,
                        postID: item.id,
                        isAuthenticated: currentUser != null,
                        datePosted: item.datePosted,
                        isLoading: false,
                        isTermly: false,
                      ),
                    );
                  },
                );
              },
              loading: () => SizedBox(
                  height: MediaQuery.of(context).size.height * .15,
                  child: NormalPostCard(
                    isLoading: true,
                    isTermly: false,
                  )),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),

            Padding(
              // Add the TextButton after the normalCards section
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: TextButton(
                onPressed: () {
                  widget.onNavigate();
                },
                child: const Text(
                  'View more articles',
                  style: TextStyle(
                    color: Color(0xFF020B40), // Match your theme/style
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // userIsNew
            //     ? const Text('Welcome New user!')
            //     : const Text('Welcome Back!'),
          ],
        ),
      ),
    );
  }
}
