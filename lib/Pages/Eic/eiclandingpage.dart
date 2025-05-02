import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Eic/eichomepage.dart';
import 'package:nuntium_mobile/Pages/Eic/historypage.dart';
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

  final List<Widget> _screens = [
    const EicHomepage(),
    const CalendarPage(),
    const TopicHistoryPage(sectionId: 'All'),
  ];

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
        pageOrigin: 'eiclanding',
      ),
      body: IndexedStack(
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
