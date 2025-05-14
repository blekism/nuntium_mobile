import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Eic/eichomepage.dart';
import 'package:nuntium_mobile/Pages/Eic/historypage.dart';
import 'package:nuntium_mobile/Pages/Eic/instacreate.dart';
import 'package:nuntium_mobile/Pages/Eic/post_for_approval.dart';
import 'package:nuntium_mobile/Pages/Eic/upload_termly.dart';
import 'package:nuntium_mobile/Pages/appdrawer.dart';
import 'package:nuntium_mobile/Pages/Calendar/calendarpage.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';

class EicLandingPage extends StatefulWidget {
  final VoidCallback? onLogout;
  final String? userRole;

  const EicLandingPage({
    super.key,
    this.onLogout,
    this.userRole,
  });

  @override
  State<EicLandingPage> createState() => _EicLandingPage();
}

class _EicLandingPage extends State<EicLandingPage> {
  int _currentIndex = 0;
  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _updateScreensAndCurrentIndex();
  }

  @override
  void didUpdateWidget(covariant EicLandingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userRole != oldWidget.userRole) {
      _updateScreensAndCurrentIndex();
    }
  }

  void _updateScreensAndCurrentIndex() {
    final baseScreens = [
      const EicHomepage(),
      const CalendarPage(),
      const TopicHistoryPage(sectionName: 'All'),
    ];

    if (widget.userRole == 'eic') {
      _screens = [...baseScreens, const PostForApproval()];
    } else {
      _screens = baseScreens;
    }

    // Ensure _currentIndex is valid for the new set of screens
    if (_currentIndex >= _screens.length) {
      setState(() {
        _currentIndex = 0; // Reset to the first tab
      });
    } else {
      // If _currentIndex is still valid, we might still need to call setState
      // if other parts of the UI depend on the new _screens list immediately.
      // However, build will be called anyway if didUpdateWidget is triggered.
      // If only _screens content changes but length and index are fine,
      // build will handle it. If index needed reset, setState above handles it.
    }
  }

  String _getAppBarTitle() {
    if (widget.userRole == 'eic') {
      return switch (_currentIndex) {
        0 => 'Sections',
        1 => 'Calendar',
        2 => 'History',
        3 => 'Post Approvals',
        _ => '',
      };
    } else {
      // For non-EIC roles, index 3 is not applicable
      return switch (_currentIndex) {
        0 => 'Sections',
        1 => 'Calendar',
        2 => 'History',
        _ => '',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_screens.isEmpty &&
        (widget.userRole != null || widget.userRole == null)) {
      _updateScreensAndCurrentIndex();
    }

    return Scaffold(
      appBar: CustomAppBar(
        appbarTitle: _getAppBarTitle(),
        hasNavigated: false,
      ),
      drawer: Appdrawer(
        onLogout: widget.onLogout!,
        userRole: widget.userRole!,
        pageOrigin: 'eiclanding',
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _bottomNavbar(),
      floatingActionButton: _adminFab(context),
    );
  }

  FloatingActionButton _adminFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        print('fab pressed');
        // Show a bottom sheet with options
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                // Use Wrap for simple layout
                children: <Widget>[
                  ListTile(
                    leading:
                        const Icon(Icons.add_circle_outline), // Example Icon 1
                    title: const Text('Article post'),
                    onTap: () {
                      Navigator.pop(context); // Close the bottom sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InstantCreate(
                            pageType: 'article',
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_album), // Example Icon 2
                    title: const Text('Photojourn post'),
                    onTap: () {
                      Navigator.pop(context); // Close the bottom sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InstantCreate(
                            pageType: 'photography',
                          ),
                        ),
                      );
                      // Example: Navigate to another page
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => const AnotherPage()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit_note), // Example Icon 2
                    title: const Text('Upload Termly'),
                    onTap: () {
                      Navigator.pop(context); // Close the bottom sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UploadTermlyPage(),
                        ),
                      );
                      // Example: Navigate to another page
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => const AnotherPage()));
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      child: const Icon(Icons.add), // Changed child to a standard icon
    );
  }

  BottomNavigationBar _bottomNavbar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = (screenWidth * 0.08).clamp(24.0, 40.0);

    List<BottomNavigationBarItem> navBarItems = [
      BottomNavigationBarItem(
        icon: Image.asset(
          'assets/images/home.png',
          width: iconSize,
          height: iconSize,
        ),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Image.asset(
          'assets/images/calendar.png',
          width: iconSize,
          height: iconSize,
        ),
        label: 'Calendar',
      ),
      BottomNavigationBarItem(
        icon: Image.asset(
          'assets/images/history.png',
          width: iconSize,
          height: iconSize,
        ),
        label: 'History',
      ),
    ];

    if (widget.userRole == 'eic') {
      navBarItems.add(
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/images/news.png',
            width: iconSize,
            height: iconSize,
          ),
          label: 'Post Approvals',
        ),
      );
    }

    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey, // Good to define for consistency
      items: navBarItems,
    );
  }
}
