import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PResetNoAcc extends StatefulWidget {
  const PResetNoAcc({super.key});

  @override
  State<PResetNoAcc> createState() => PResetNoAccState();
}

class PResetNoAccState extends State<PResetNoAcc> {
  final _formKeyLog = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  String _errorMessage = '';

  Future<void> _resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _errorMessage = 'Password reset email sent. Please check your inbox.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Error sending reset email: ${e.message}';
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
                  controller: _emailController,
                  cursorColor: const Color(0XFF020B40),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0XFFF5F5F5),
                    labelText: 'Password',
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
                      return 'Please enter your email';
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
                      _resetPassword(_emailController.text.trim());
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
                      'Send Password Reset Email',
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
