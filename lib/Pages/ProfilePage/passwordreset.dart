import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class PasswordResetModal extends StatefulWidget {
  final VoidCallback? onLogout;

  const PasswordResetModal({
    super.key,
    this.onLogout,
  });

  @override
  State<PasswordResetModal> createState() => PasswordResetModalState();
  //TODO SEPARATE YUNG CHANGE PASSWORD PAG GALING SA LOGIN AND SA PROFILE
}

class PasswordResetModalState extends State<PasswordResetModal> {
  final _formKeyLog = GlobalKey<FormState>();
  final GoogleSignIn _googleSignInLog = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController currentPassword = TextEditingController();
  final TextEditingController newPassword = TextEditingController();
  final TextEditingController confirmNewPassword = TextEditingController();
  String _errorMessage = '';

  Future<void> _changePassword() async {
    try {
      // Re-authenticate the user (required for sensitive actions like password change)
      final credential = EmailAuthProvider.credential(
          email: user!.email!, password: currentPassword.text);
      await user!.reauthenticateWithCredential(credential);

      // Update the password
      await user!.updatePassword(newPassword.text);

      // Password updated successfully, now sign out the user
      try {
        await _auth.signOut();
        await _googleSignInLog.signOut();
        widget.onLogout!();

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

      // Optionally, navigate to the login screen or show a success message
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Error changing password: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Form(
          key: _formKeyLog,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Change your password'),
              const SizedBox(height: 15),
              SizedBox(
                width: MediaQuery.of(context).size.width * .8,
                child: TextFormField(
                  controller: currentPassword,
                  cursorColor: const Color(0XFF020B40),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0XFFF5F5F5),
                    labelText: 'Current Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0XFF020B40),
                      ),
                    ),
                    labelStyle: const TextStyle(
                      color: Color(0xFF020B40),
                      fontSize: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: MediaQuery.of(context).size.width * .8,
                child: TextFormField(
                  controller: newPassword,
                  cursorColor: const Color(0XFF020B40),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0XFFF5F5F5),
                    labelText: 'New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0XFF020B40),
                      ),
                    ),
                    labelStyle: const TextStyle(
                      color: Color(0xFF020B40),
                      fontSize: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your new password';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: MediaQuery.of(context).size.width * .8,
                child: TextFormField(
                  controller: confirmNewPassword,
                  cursorColor: const Color(0XFF020B40),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0XFFF5F5F5),
                    labelText: 'Confirm new password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0XFF020B40),
                      ),
                    ),
                    labelStyle: const TextStyle(
                      color: Color(0xFF020B40),
                      fontSize: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'please confirm your password';
                    }

                    if (value != newPassword.text) {
                      return 'passwords do not match';
                    }

                    return null;
                  },
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                height: 60,
                width: MediaQuery.of(context).size.width * .9,
                child: ElevatedButton(
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    if (_formKeyLog.currentState?.validate() ?? false) {
                      _changePassword();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0XFF020B40),
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Password reset',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
