import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Contributors/Templates/homepagetemplate.dart';
import 'package:nuntium_mobile/Pages/Calendar/calendarpage.dart';
import 'package:nuntium_mobile/Pages/appdrawer.dart';

class SectionWriterHomePage extends StatefulWidget {
  final VoidCallback? onLogout;
  final String? userRole;

  const SectionWriterHomePage({
    super.key,
    this.onLogout,
    this.userRole,
  });

  @override
  State<SectionWriterHomePage> createState() => _SectionWriterHomePage();
}

class _SectionWriterHomePage extends State<SectionWriterHomePage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CalendarPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      drawer: Appdrawer(
        onLogout: widget.onLogout!,
        userRole: widget.userRole!,
        pageOrigin: 'section_writer',
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
      selectedItemColor: Colors.blue,
      items: [
        BottomNavigationBarItem(
          icon: Image.asset('assets/images/home.png', width: 35, height: 35),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon:
              Image.asset('assets/images/bookmarks.png', width: 35, height: 35),
          label: 'Calendar',
        ),
        // BottomNavigationBarItem(
        //   icon: Image.asset('assets/images/history.png', width: 35, height: 35),
        //   label: 'Chat',
        // ),
      ],
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
    return const HomePageTemplate();
  }
}
