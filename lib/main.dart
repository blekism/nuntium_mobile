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
import 'Pages/Homepage/contribhuntpage.dart';
import 'Pages/Contributors/contribhomepage.dart';
import 'Pages/Calendar/calendarpage.dart';
import 'Pages/Calendar/createeventpage.dart';
import 'Pages/Calendar/viewcreatedevent.dart';
import 'Pages/ContentPage/articlecontent.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Pages/Eic/eiclandingpage.dart';
import 'Pages/Eic/eichomepage.dart';
import 'Pages/Eic/eicorgtasks.dart';
import 'Pages/SectionEditor/Templates/assigntaskpage.dart';
import 'Pages/SectionEditor/assigntasklogpage.dart';
import 'Pages/SectionWriter/swhomepage.dart';
import 'Pages/Committee/committeehomepage.dart';
import 'Pages/Committee/committeehometemplate.dart';
import 'Pages/Committee/taskcontentpage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
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
        // '/profile': (context) => const ProfilePage(),
        // '/joinus': (context) => const JoinUsPage(),
        '/contribhomepage': (context) => const ContribHomePage(),
        '/eiclandingpage': (context) => const EicLandingPage(),
        '/calendarpage': (context) => const CalendarPage(),
        '/createeventpage': (context) => const CreateEventPage(),
        '/viewcreatedevent': (context) => const ViewCreatedEventPage(),
        '/eichomepage': (context) => const EicHomepage(),
        '/eicorgtasks': (context) => const OrganizationTasks(),
        '/assigntaskpage': (context) => const AssignTaskPage(),
        '/assigntasklogpage': (context) => const AssignTaskLogPage(),
        '/swhomepage': (context) => const SectionWriterHomePage(),
        '/contribhuntpage': (context) => const ContribHuntPage(),
        '/commmitteehomepage': (context) => const CommitteeHomePage(),
        '/commmitteehometemplate': (context) =>
            const CommitteeHomePageTemplate(),
        '/taskcontentpage': (context) => const TaskContentPage(),
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
  String? userRole;
  bool isLoading = true;

  Future<void> getUserRole(
      String uid, String? email, String? displayName, String? photoURL) async {
    print('getUserRole called at ${DateTime.now()}');
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        print('New user detected, creating Firestore record...');
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': email,
          'uid': uid,
          'username': displayName,
          'photoURL': photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'reader',
        });
        userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
      }

      if (mounted) {
        if (userDoc.exists) {
          print('User document exists.');
          print('User name is ${displayName ?? 'No name'}');
          final role = userDoc['role'] as String?;
          print('User role is $role');
          if (role != null) {
            setState(() {
              userRole = role;
              isLoading = false;
            });
          }
        } else {
          print('User document still does not exist.');
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching user role: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _onSignOut() {
    print('user role not cleared yet ${userRole}');

    setState(() {
      userRole = null;
      isLoading = true;
    });

    print('user role cleared ${userRole}');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authStream,
      builder: (context, snapshot) {
        print('Auth state changed at ${DateTime.now()}');
        if (snapshot.data == null) {
          return Homepage(
            onLogout: _onSignOut,
            userRole: null,
          );
        }

        if (ConnectionState.active == snapshot.connectionState &&
            snapshot.hasData) {
          if (snapshot.data!.emailVerified) {
            print('user email verified now at ${DateTime.now()}');

            if (userRole == null && isLoading) {
              getUserRole(
                snapshot.data!.uid,
                snapshot.data!.email,
                snapshot.data!.displayName,
                snapshot.data!.photoURL,
              );
              return const Center(child: CircularProgressIndicator());
            }

            switch (userRole) {
              case 'reader':
                return Homepage(
                  onLogout: _onSignOut,
                  userRole: userRole,
                );
              case 'contributor':
                return ContribHomePage(
                  onLogout: _onSignOut,
                  userRole: userRole,
                );
              case 'section_writer':
                return SectionWriterHomePage(
                  onLogout: _onSignOut,
                  userRole: userRole,
                );
              case 'eic':
                return EicLandingPage(
                  onLogout: _onSignOut,
                  userRole: userRole,
                );
              case 'section_editors':
                return EditorsHomePage(
                  onLogout: _onSignOut,
                  userRole: userRole,
                );
              case 'committee':
                return CommitteeHomePage(
                  onLogout: _onSignOut,
                  userRole: userRole,
                );
              default:
                print(
                    'early exit sa login due to future error at ${DateTime.now()}');
                return const LoginPage();
            }
          } else {
            print('no exit ya hehe');
            WidgetsBinding.instance.addPostFrameCallback(
              (_) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VerifyPage(
                      onLogout: _onSignOut,
                    ),
                  ),
                );
              },
            );
          }
        } else {
          print('User logged out. Resetting role.');
          print('User name is ${snapshot.data?.displayName ?? 'No name'}');
          return const LoginPage();
        }
        return const SizedBox.shrink();
      },
    );
  }
}
