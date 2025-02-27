import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nuntium_mobile/Pages/Eic/eichomepage.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _currentIndex = 0;
  bool canUsersRead = false;

  Future<bool> _canUserRead() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      return userDoc.get('canUserRead') ?? false;
    } catch (e) {
      print("Error fetching canUserRead: $e");
      return false; // Return false in case of an error
    }
  }

  @override
  void initState() {
    super.initState();

    _canUserRead().then((value) {
      setState(() {
        canUsersRead = value;
      });
    });
  }

  final List<Widget> _screens = [
    const EicHomepage(),
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
        canUsersRead: canUsersRead,
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
      ],
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      title: const Text(
        'Nuntium',
        style: TextStyle(
          color: Colors.black,
          fontSize: 24,
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
