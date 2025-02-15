import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nuntium_mobile/Pages/Contributors/Templates/homepagetemplate.dart';
import 'calendarpage.dart';

class ContribHomePage extends StatefulWidget {
  const ContribHomePage({super.key});

  @override
  State<ContribHomePage> createState() => _ContribHomePage();
}

class _ContribHomePage extends State<ContribHomePage> {
  final GoogleSignIn _googleSignInLog = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _currentIndex = 0;

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
    HomeScreen(),
    const CalendarPage(),
  ];
  @override
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

  Drawer _drawer(BuildContext context) {
    return Drawer(
      shadowColor: Colors.black,
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xffD9D9D9)),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.black, fontSize: 24),
            ),
          ),
          ListTile(
            title: const Text('Profile'),
            onTap: () {
              // Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            title: const Text('Change to Reader Mode!'),
            onTap: () {
              // Navigator.pushNamed(context, '/joinus');
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
    return HomePageTemplate();
  }
}
