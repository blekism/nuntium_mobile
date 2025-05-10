import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nuntium_mobile/Pages/Eic/historypage.dart';
import 'package:nuntium_mobile/Pages/Homepage/aboutpage.dart';
import 'package:nuntium_mobile/Pages/Homepage/homepage.dart';
import 'package:nuntium_mobile/Pages/Homepage/readhistory.dart';
import 'package:nuntium_mobile/Pages/Homepage/savedpostspage.dart';
import 'package:nuntium_mobile/Pages/ProfilePage/profilepage.dart';
import 'package:nuntium_mobile/providers/provider_invalidator.dart';

class Appdrawer extends ConsumerStatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback? logoutInReader;
  final String userRole;
  final String? pageOrigin;

  const Appdrawer({
    super.key,
    required this.onLogout,
    this.logoutInReader,
    required this.userRole,
    this.pageOrigin,
  });

  @override
  ConsumerState<Appdrawer> createState() => _AppdrawerState();
}

class _AppdrawerState extends ConsumerState<Appdrawer> {
  final GoogleSignIn _googleSignInLog = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
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

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      await _googleSignInLog.signOut();
      widget.onLogout();

      ProviderInvalidator.invalidateAll(ref);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/initial',
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
              Navigator.pop(context);

              _auth.currentUser != null
                  ? Navigator.push(context,
                      MaterialPageRoute(builder: (context) {
                      return ProfilePage(
                        onLogout: widget.onLogout,
                      );
                    }))
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please log in to continue'),
                        backgroundColor: Colors.black,
                      ),
                    );
            },
          ),
          widget.userRole == 'reader'
              ? ListTile(
                  title: const Text('Contributors Hunt'),
                  onTap: () {
                    Navigator.pushNamed(context, '/contribhuntpage');
                  },
                )
              : const SizedBox.shrink(),
          widget.userRole != 'reader' &&
                  FirebaseAuth.instance.currentUser != null
              ? ListTile(
                  title: const Text('Work History'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TopicHistoryPage(
                                userId: FirebaseAuth.instance.currentUser!.uid,
                              )),
                    );
                  },
                )
              : const SizedBox.shrink(),
          ListTile(
            title: const Text('Read History'),
            onTap: () {
              Navigator.pop(context);
              _auth.currentUser != null
                  ? Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoryPage(
                          userRole: widget.userRole,
                        ),
                      ),
                    )
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please log in to continue'),
                        backgroundColor: Colors.black,
                      ),
                    );
            },
          ),
          ListTile(
            title: const Text('Bookmarks'),
            onTap: () {
              Navigator.pop(context);
              _auth.currentUser != null
                  ? Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SavedPage(
                          userRole: widget.userRole,
                        ),
                      ),
                    )
                  : ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please log in to continue'),
                        backgroundColor: Colors.black,
                      ),
                    );
            },
          ),
          widget.userRole != 'reader'
              ? _changeButtonPerRole(widget.pageOrigin!)
              : const SizedBox.shrink(),
          widget.userRole != 'none'
              ? ListTile(
                  title: const Text('Logout!'),
                  onTap: () {
                    _logout();
                  })
              : ListTile(
                  title: const Text('Log in Now!'),
                  onTap: () {
                    widget.onLogout();
                    Navigator.pushReplacementNamed(
                      context,
                      '/login',
                    );
                  }),
          ListTile(
            title: const Text('About Us'), //TODO convert to about us ang page
            onTap: () {
              _auth.currentUser != null
                  ? Navigator.push(context,
                      MaterialPageRoute(builder: (context) {
                      return const AboutUsPage();
                    }))
                  : null;
            },
          ),
        ],
      ),
    );
  }

  Widget _changeButtonPerRole(String pageOrigin) {
    switch (pageOrigin) {
      case 'eiclanding':
      case 'section_editors':
      case 'contributor':
      case 'section_writer':
        return ListTile(
          title: const Text('Change to Reader Mode!'),
          onTap: () {
            Navigator.pop(context);

            canUsersRead == true
                ? Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return Homepage(
                      onLogout: widget.onLogout,
                      userRole: widget.userRole,
                    );
                  }))
                : null;
          },
        );
      case 'reader':
        return widget.userRole != "none"
            ? ListTile(
                title: const Text('Exit Reader Mode!'),
                onTap: () {
                  print('page origin is ${widget.pageOrigin}');

                  // First pop closes the drawer
                  Navigator.pop(context);

                  // Second pop navigates back to the previous page
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              )
            : const SizedBox.shrink();

      default:
        return const SizedBox.shrink(); // Or a suitable default widget
    }
  }
}
