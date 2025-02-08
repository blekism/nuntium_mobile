import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _branch = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final emailRegex =
      RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
  final passwordRegex =
      RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');

  Future<User?> signInWithOwnCredentials(
      String email, password, username) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      final User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(username);
        final DocumentSnapshot doc =
            await db.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          await db.collection('users').doc(user.uid).set({
            'email': user.email,
            'password': password,
            'username': username,
            'branch': _branch.text,
            'uid': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'creation': user.metadata.creationTime,
            'lastSignIn': user.metadata.lastSignInTime,
          });
        } else {
          print('User already exists in Firestore');
          return null;
        }

        try {
          await user.sendEmailVerification();
          print('Verification email sent to ${user.email}');
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
        return user;
      }
      return null; //shoulnd't happen but good to have
    } catch (e) {
      print("Error signing in with own credentials: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/nudasma.jpg', // Replace with your image path
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          // Semi-transparent overlay color
          Positioned.fill(
            child: Container(
              color: const Color(0XFFD4AF37)
                  .withOpacity(0.4), // Adjust opacity as needed
            ),
          ),

          SingleChildScrollView(
            child: Stack(
              children: [
                Center(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.1,
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.9,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0XFFF9F9F9),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(50),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Form(
                              key: _formKey,
                              child: Flex(
                                direction: Axis.vertical,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Readable',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Lets get you started',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _usernameController,
                                    cursorColor: const Color(0XFF020B40),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0XFFF5F5F5),
                                      labelText: 'Username',
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF020B40),
                                        fontSize: 12,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0XFF020B40),
                                        ),
                                      ),
                                      focusColor: const Color(0XFF020B40),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your username';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _emailController,
                                    cursorColor: const Color(0XFF020B40),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0XFFF5F5F5),
                                      labelText: 'Email',
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF020B40),
                                        fontSize: 12,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0XFF020B40),
                                        ),
                                      ),
                                      focusColor: const Color(0XFF020B40),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!emailRegex.hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
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
                                        return 'Please enter your password';
                                      }
                                      if (!passwordRegex.hasMatch(value)) {
                                        return 'Password must be at least 8 characters long and include at least one uppercase letter, one lowercase letter, one number, and one special character';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 5),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: true,
                                    cursorColor: const Color(0XFF020B40),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0XFFF5F5F5),
                                      labelText: 'Confirm Password',
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
                                        return 'Please confirm your password';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 5),
                                  DropdownButtonFormField<String>(
                                    onChanged: (String? newValue) {
                                      _branch.text = newValue!;
                                    },
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0XFFF5F5F5),
                                      labelText: 'Branch',
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF020B40),
                                        fontSize: 12,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0XFF020B40),
                                        ),
                                      ),
                                      focusColor: const Color(0XFF020B40),
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white, // Text color white
                                    ),
                                    items: <String>[
                                      'Nu Dasma',
                                      'Nu Manila',
                                      'Nu Imus',
                                      'Nu Clark',
                                    ].map<DropdownMenuItem<String>>(
                                        (String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          value,
                                          style: const TextStyle(
                                              color: Colors.black),
                                        ),
                                      );
                                    }).toList(),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select your branch';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    height: 60,
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (_formKey.currentState?.validate() ??
                                            false) {
                                          User? user =
                                              await signInWithOwnCredentials(
                                                  _emailController.text,
                                                  _passwordController.text,
                                                  _usernameController.text);
                                          // _handleSignUpResult(user);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0XFF020B40),
                                        elevation: 10,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(
                                    color: Color(0xFFD9D9D9),
                                    height: 20,
                                    thickness: 2,
                                    indent: 20,
                                    endIndent: 20,
                                  ),
                                  const SizedBox(height: 20),
                                  Align(
                                    alignment: AlignmentDirectional.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'have an account?',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text(
                                            'Log in now',
                                            style: TextStyle(
                                              color: Color(0XFF020B40),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
