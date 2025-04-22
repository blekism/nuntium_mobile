import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

class _VerifyPageState extends State<VerifyPage> {
  static bool _hasSentVerification = false;
  bool _isResending = false;
  Timer? _checkEmailVerifiedTimer;

  @override
  void initState() {
    super.initState();
    _maybeSendVerificationEmail();

    // Periodically check if user has verified their email
    _checkEmailVerifiedTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        print('User has been verified kaya proceed na');
        timer.cancel();
        _navigateToInitialPage();
      } else {
        print('User is not verified, retrying...');
      }
    });
  }

  @override
  void dispose() {
    _checkEmailVerifiedTimer?.cancel();
    super.dispose();
  }

  void _maybeSendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified && !_hasSentVerification) {
      try {
        print('bilangin mo gagu');
        await user.sendEmailVerification();
        _hasSentVerification = true;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text("Verification email sent. Please check your inbox."),
            ),
          );
        }
      } catch (e) {
        print("Error sending verification email: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "an email has already been sent to your inbox, if you don't see one, please try again in a few minutes"),
            ),
          );
        }
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (widget.user != null && !widget.user!.emailVerified) {
      setState(() {
        _isResending = true;
      });

      try {
        await widget.user!.sendEmailVerification();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Verification email resent."),
            ),
          );
        }
      } catch (e) {
        print("Error resending verification email: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
            ),
          );
        }
      }

      setState(() {
        _isResending = false;
      });
    }
  }

  void _navigateToInitialPage() {
    Navigator.of(context).pushReplacementNamed('/initial');
  }

  void _logout() {
    FirebaseAuth.instance.signOut();
    widget.onLogout?.call();
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
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _isResending ? null : _resendVerificationEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF020B40),
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _isResending ? 'Sending...' : 'Resend Verification Email',
                    style: const TextStyle(
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
                    backgroundColor: const Color(0xFFB00020),
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
