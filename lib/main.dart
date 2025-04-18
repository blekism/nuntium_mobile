import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/ContentPage/articlepage.dart';
import 'package:nuntium_mobile/Pages/EditorialBoard/eb_landing_page.dart';
import 'package:nuntium_mobile/Pages/EditorialSecMembers/sec_member_landing_page.dart';
import 'package:nuntium_mobile/Pages/Eic/create_task_page.dart';
import 'package:nuntium_mobile/Pages/Eic/eiclandingpage.dart';
import 'package:nuntium_mobile/Pages/Homepage/contribhuntpage.dart';
import 'package:nuntium_mobile/Pages/ProfilePage/passwordreset.dart';
import 'package:nuntium_mobile/Pages/ProfilePage/passwordreset_noacc.dart';
import 'package:nuntium_mobile/Pages/ProfilePage/profilepage.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
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
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  await requestNotificationPermission();

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({
        "fcmToken": newToken,
      });
    }
  });

  runApp(const ProviderScope(child: NuntiumApp()));
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Access title and body from the data payload
  String? title = message.data['title'];

  print("🔔 Background message received!");
  print("Title: $title");

  // Optionally trigger a local notification here if needed
}

Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("Notification permission granted.");
  } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
    print("Notification permission denied.");
  }
}

class NuntiumApp extends StatelessWidget {
  const NuntiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      initialRoute: '/initial',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/verify': (context) => const VerifyPage(),
        '/homepage': (context) => const Homepage(),
        '/discover': (context) => const DiscoverPage(),
        '/saved': (context) => const SavedPage(),
        '/history': (context) => const HistoryPage(),
        '/termly': (context) => const TermlyPage(),
        '/contentpage': (context) => const ArticlePage(),
        // '/sectioneditorhome': (context) => const EditorsHomePage(),
        '/profile': (context) => const ProfilePage(),
        '/contribhuntpage': (context) => const ContribHuntPage(),
        '/passreset': (context) => const PasswordResetModal(),
        '/presetnoacc': (context) => const PResetNoAcc(),
        '/createtask': (context) => const CreateTaskPage(),

        // // '/joinus': (context) => const JoinUsPage(),
        // '/contribhomepage': (context) => const ContribHomePage(),
        // '/eiclandingpage': (context) => const EicLandingPage(),
        // '/calendarpage': (context) => const CalendarPage(),
        // '/createeventpage': (context) => const CreateEventPage(),
        // '/viewcreatedevent': (context) => const ViewCreatedEventPage(),
        // '/eichomepage': (context) => const EicHomepage(),
        // '/eicorgtasks': (context) => const OrganizationTasks(),
        // '/assigntaskpage': (context) => const AssignTaskPage(),
        // '/assigntasklogpage': (context) => const AssignTaskLogPage(),
        // '/swhomepage': (context) => const SectionWriterHomePage(),

        // '/commmitteehomepage': (context) => const CommitteeHomePage(),
        // '/commmitteehometemplate': (context) =>
        //     const CommitteeHomePageTemplate(),
        // '/taskcontentpage': (context) => const TaskContentPage(),
        // '/completedtaskitems': (context) =>
        //     const CompletedItems(title: '', description: ''),
        // '/historypage': (context) => const TaskHistoryPage(),
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
  final firebaseFunctions = FirebaseFunctions();

  Future<void> getUserRole(
      String uid, String? email, String? displayName, String? photoURL) async {
    try {
      DocumentSnapshot userDoc = await firebaseFunctions.getUserDoc(uid);

      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': email,
          'uid': uid,
          'username': displayName,
          'photoURL': photoURL ??
              'https://firebasestorage.googleapis.com/v0/b/nu-publication-system.firebasestorage.app/o/logo.jpg?alt=media&token=fed28218-248d-4ad9-a639-14f072f7e9b9',
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'reader',
        });
        userDoc = await firebaseFunctions.getUserDoc(uid);
      }

      if (mounted) {
        if (userDoc.exists) {
          final role = userDoc['role'] as String?;
          if (role != null) {
            setState(() {
              userRole = role;
              isLoading = false;
            });
          }
        } else {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
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
        if (snapshot.data == null) {
          return Homepage(
            onLogout: _onSignOut,
            userRole: null,
          );
        }

        if (ConnectionState.active == snapshot.connectionState &&
            snapshot.hasData) {
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
            // case 'contributor':
            //   return ContribHomePage(
            //     onLogout: _onSignOut,
            //     userRole: userRole,
            //   );
            case 'section_writer':
              return SecMemberLandingPage(
                onLogout: _onSignOut,
                userRole: userRole,
                uid: snapshot.data!.uid,
              );
            case 'eic':
              return EicLandingPage(
                onLogout: _onSignOut,
                userRole: userRole,
              );
            case 'section_editors':
              return EbLandingPage(
                onLogout: _onSignOut,
                userRole: userRole,
              );
            default:
              return const LoginPage();
          }
        } else {
          return const LoginPage();
        }
        //  return const SizedBox.shrink();
      },
    );
  }
}
