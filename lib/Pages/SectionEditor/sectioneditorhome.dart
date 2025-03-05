import "package:flutter/material.dart";
import 'package:nuntium_mobile/Pages/SectionEditor/assigntasklogpage.dart';
import 'package:nuntium_mobile/Pages/SectionEditor/Templates/sectioneditorhometemplate.dart';
import 'package:nuntium_mobile/Pages/Contributors/calendarpage.dart';
import 'package:nuntium_mobile/Pages/appdrawer.dart';

class EditorsHomePage extends StatefulWidget {
  final VoidCallback? onLogout;
  final String? userRole;

  const EditorsHomePage({
    super.key,
    this.onLogout,
    this.userRole,
  });

  @override
  State<EditorsHomePage> createState() => _EditorsHomePageState();
}

class _EditorsHomePageState extends State<EditorsHomePage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AssignTaskLogPage(),
    const CalendarPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFFFFFFFF),
      appBar: _appBar(context),
      drawer: Appdrawer(
        onLogout: widget.onLogout!,
        userRole: widget.userRole!,
        pageOrigin: 'section_editors',
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
    return AppBar(
      backgroundColor: Colors.white,
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return const SectionEditorHomePage();
  }
}
