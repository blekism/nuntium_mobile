import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'Pages/ContentPage/articlecontent.dart';
import 'package:google_fonts/google_fonts.dart';

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
        // '/comments': (context) => const CommentsPage(),
        // '/profile': (context) => const ProfilePage(),
        // '/joinus': (context) => const JoinUsPage(),
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
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.authStream,
      builder: (context, snapshot) {
        print('Auth state changed at ${DateTime.now()}');
        if (ConnectionState.active == snapshot.connectionState &&
            snapshot.hasData) {
          print(
              'user is verified: ${snapshot.data!.emailVerified} at ${DateTime.now()}');
          if (snapshot.data!.emailVerified) {
            print(
                'user is verified going to homepage ${snapshot.data!.email} at ${DateTime.now()}');
            return const Homepage();
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
