import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Pages/SectionEditor/sectioneditorhome.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Pages/LoginRegister/login_page.dart';
import 'Pages/LoginRegister/registerpage.dart';
import 'Pages/LoginRegister/verifyuser.dart';
import 'Pages/Homepage/homepage.dart';
import 'Pages/Homepage/discoverpage.dart';
import 'Pages/Homepage/savedpostspage.dart';
import 'Pages/Homepage/termlypostspage.dart';
import 'Pages/Homepage/readhistory.dart';
import 'Pages/Contributors/contribhomepage.dart';
import 'Pages/Contributors/calendarpage.dart';
import 'Pages/ContentPage/articlecontent.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const NuntiumApp());
}

class NuntiumApp extends StatelessWidget {
  const NuntiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(textTheme: GoogleFonts.poppinsTextTheme()),
      initialRoute: '/initial',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/verify': (context) => const VerifyPage(),
        // '/exitConfirm': (context) => const ExitConfirmPage(),
        '/homepage': (context) => const Homepage(),
        '/discover': (context) => const DiscoverPage(),
        '/saved': (context) => const SavedPage(),
        '/history': (context) => const HistoryPage(),
        '/termly': (context) => const TermlyPage(),
        '/contentpage': (context) => const ContentPage(),
        '/sectioneditorhome': (context) => const EditorsHomePage(),
        // '/comments': (context) => const CommentsPage(),
        // '/profile': (context) => const ProfilePage(),
        // '/joinus': (context) => const JoinUsPage(),
        '/contribhomepage': (context) => const ContribHomePage(),
        '/calendarpage': (context) => const CalendarPage(),
        '/initial': (context) => AuthChecker(
              authStream: FirebaseAuth.instance.authStateChanges(),
            ),
      },
    );
  }
}

class AuthChecker extends StatefulWidget {
  final authStream;

  const AuthChecker({super.key, required this.authStream});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc['role'] as String?;
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authStream,
      builder: (context, snapshot) {
        // print('Auth state changed at ${DateTime.now()}');
        if (ConnectionState.active == snapshot.connectionState &&
            snapshot.hasData) {
          if (snapshot.data!.emailVerified) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator()); // Show loading indicator
                } else if (snapshot.hasError) {
                  print('Error fetching user role: ${snapshot.error}');
                  return const Homepage(); // Or handle the error as needed
                } else if (snapshot.hasData && snapshot.data!.exists) {
                  final userData = snapshot.data!.data()
                      as Map<String, dynamic>?; // Cast to Map
                  final userRole =
                      userData?['role'] as String?; // Get the role, handle null
                  print('user role: $userRole at ${DateTime.now()}');

                  if (userRole != null) {
                    if (userRole == 'reader') {
                      return const Homepage();
                    } else if (userRole == 'contributor') {
                      return const ContribHomePage();
                      // } else if (userRole == 'section writers') {
                      //   return const WritersHomePage();
                    } else if (userRole == 'section_editors') {
                      return const EditorsHomePage();
                      // }
                      //else if (userRole == 'editor in chief') {
                      //   return const EICHomePage();
                    } else {
                      return const LoginPage(); // Default user homepage
                    }
                  }
                }
                return const LoginPage(); // Default if user data is missing
              },
            );
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamed(context, '/verify');
            });
          }
        } else {
          return const LoginPage();
        }
        return const SizedBox.shrink();
      },
    );
  }
}
