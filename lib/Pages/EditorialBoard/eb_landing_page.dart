import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/Calendar/calendarpage.dart';
import 'package:nuntium_mobile/Pages/Eic/historypage.dart';
import 'package:nuntium_mobile/Pages/Eic/instacreate.dart';
import 'package:nuntium_mobile/Pages/Eic/topicpage.dart';
import 'package:nuntium_mobile/Pages/Eic/upload_termly.dart';
import 'package:nuntium_mobile/Pages/appdrawer.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/models/eb_section_model.dart';

class EbLandingPage extends ConsumerStatefulWidget {
  final VoidCallback? onLogout;
  final String? userRole;

  const EbLandingPage({
    super.key,
    this.onLogout,
    this.userRole,
  });

  @override
  ConsumerState<EbLandingPage> createState() => _EbLandingPageState();
}

class _EbLandingPageState extends ConsumerState<EbLandingPage> {
  late final FirebaseFunctions firebaseFunctions;
  EbSectionModel? sectionData;
  String? sectionName;
  bool isLoading = true;
  String? errorMessage;
  List<Widget> _screens = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    firebaseFunctions = FirebaseFunctions();

    _loadSectionData();
  }

  Future<void> _loadSectionData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null) {
        throw Exception('No User is Logged in');
      }

      final section = await firebaseFunctions.getEbSection(uid);
      setState(() {
        _screens = [
          TopicPage(
            sectionName: section.sectionName,
            shouldShowAppbar: false,
            secEd: true,
          ),
          const CalendarPage(),
          TopicHistoryPage(sectionName: section.sectionName),
        ];

        sectionData = section;
        sectionName = section.sectionName;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appbarTitle: switch (_currentIndex) {
          0 => 'Homepage',
          1 => 'Calendar',
          2 => 'History',
          _ => '',
        },
        hasNavigated: false,
      ),
      drawer: Appdrawer(
        onLogout: widget.onLogout!,
        userRole: widget.userRole!,
        pageOrigin: 'section_editors',
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
      bottomNavigationBar: _bottomNavbar(),
      floatingActionButton: isLoading
          ? FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.cancel),
            )
          : _adminFab(context, sectionName!),
    );
  }

  BottomNavigationBar _bottomNavbar() {
    // Calculate responsive icon size based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = (screenWidth * 0.08).clamp(24.0, 40.0);

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
      ],
    );
  }

  FloatingActionButton _adminFab(BuildContext context, String creatorSection) {
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
}
