import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/Calendar/calendarpage.dart';
import 'package:nuntium_mobile/Pages/Eic/topicpage.dart';
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
            sectionID: section.sectionId,
            sectionName: section.sectionName,
            shouldShowAppbar: false,
            secEd: true,
          ),
          const CalendarPage(),
        ];

        sectionData = section;
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
      appBar: const CustomAppBar(
        appbarTitle: 'Homepage',
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
      ],
    );
  }
}
