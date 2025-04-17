import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class VerifyPage extends StatefulWidget {
  final VoidCallback? onLogout;
  final User? user;

  const VerifyPage({
    super.key,
    this.onLogout,
    this.user,
  });

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> with WidgetsBindingObserver {
  bool _isVerified = false; // Stores email verification status
  Timer? _timer; // Timer to check verification status automatically

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    sendEmailVerification(widget.user!);
    _checkVerificationStatus(); // Initial check when page loads
    _startAutoCheck(); // Start auto-checking in the background
  }

  Future<void> sendEmailVerification(User user) async {
    if (user.emailVerified) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/initial',
        (Route<dynamic> route) => false,
      );
    } else {
      try {
        await user.sendEmailVerification();
        print('Verification email sent to ${user.email}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Email verification sent to your email. Please verify your email to continue.",
              ),
            ),
          );
        }
      } catch (e) {
        print("Error sending verification email: $e");
        // Handle the error, e.g., show a SnackBar to the user.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Error sending verification email. Please check your connection.",
              ),
            ),
          );
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Called when the app is resumed
      _checkVerificationStatus(); // Check verification status again
    }
  }

  Future<void> _checkVerificationStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload(); // Refresh user info from Firebase
    print('is user verified ${user?.emailVerified}');

    if (user != null && user.emailVerified) {
      setState(() {
        _isVerified = user.emailVerified;
        print('setstate changes is: ${user.emailVerified}');
      });

      if (!mounted) return;
      if (user.emailVerified == true) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/initial',
          (Route<dynamic> route) => false,
        );
      } else {
        print('User is not verified');
      }
    }
  }

  void _startAutoCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkVerificationStatus();
      print('Checking verification status: ${_isVerified}');
      if (_isVerified) {
        timer.cancel(); // Stop checking once verified
      }
    });
  }

  // 🔹 Function to resend the verification email
  Future<void> _resendVerificationEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Verification email sent! Check your inbox.")),
      );
    }
  }

  Future<void> _logout() async {
    _timer?.cancel();
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      print('redirected upon logout');
      // widget.onLogout!();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/initial',
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(13),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Verification Required',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Check your email to verify\nyour account',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _isVerified
                  ? Image.asset(
                      'assets/images/verified.png',
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    )
                  : SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _resendVerificationEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF020B40),
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Resend Verification Email',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF020B40),
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Exit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Once verified, you will be redirected automatically.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
