import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/Calendar/calendarpage.dart';
import 'package:nuntium_mobile/Pages/EditorialSecMembers/member_tasks_page.dart';
import 'package:nuntium_mobile/Pages/Eic/historypage.dart';
// import 'package:nuntium_mobile/Pages/Eic/topicpage.dart';
import 'package:nuntium_mobile/Pages/appdrawer.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class SecMemberLandingPage extends ConsumerStatefulWidget {
  final VoidCallback? onLogout;
  final String? userRole, uid;

  const SecMemberLandingPage({
    super.key,
    this.onLogout,
    this.userRole,
    this.uid,
  });

  @override
  ConsumerState<SecMemberLandingPage> createState() =>
      _SecMemberLandingPageState();
}

class _SecMemberLandingPageState extends ConsumerState<SecMemberLandingPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userSec =
        ref.watch(userSectionProvider(FirebaseAuth.instance.currentUser!.uid));

    return Scaffold(
      appBar: CustomAppBar(
        appbarTitle: switch (_currentIndex) {
          0 => 'Your Tasks',
          1 => 'Calendar',
          2 => 'Section History',
          _ => '',
        },
        hasNavigated: false,
      ),
      drawer: Appdrawer(
        onLogout: widget.onLogout!,
        userRole: widget.userRole!,
        pageOrigin: 'section_writer',
      ),
      body: userSec.when(
        data: (userSec) {
          return IndexedStack(
            index: _currentIndex,
            children: [
              MemberTasksPage(uid: widget.uid),
              const CalendarPage(),
              TopicHistoryPage(sectionId: userSec.sectionId),
            ],
          );
        },
        error: (error, stack) => Center(child: Text('Error: $error')),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
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
}
