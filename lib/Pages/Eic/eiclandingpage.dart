import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Eic/eichomepage.dart';
import 'package:nuntium_mobile/Pages/SectionEditor/assigntasklogpage.dart';
import 'package:nuntium_mobile/Pages/appdrawer.dart';

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
    const AssignTaskLogPage(
      section: 'all',
    ),
    // const HomeScreen(),
    // const CalendarPage(),
    // const CreateTaskPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
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
            'assets/images/assigntask.png',
            width: iconSize,
            height: iconSize,
          ),
          label: 'Assign Task',
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

  AppBar _appBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // Get screen width
    final titleFontSize = (screenWidth * 0.06).clamp(18.0, 24.0);

    return AppBar(
      backgroundColor: Colors.transparent,
      title: Text(
        'Nuntium',
        style: TextStyle(
          color: Colors.black,
          fontSize: titleFontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () {
            print('notif clicked');
          },
          child: Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width * 0.2,
            margin: const EdgeInsets.all(5),
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
