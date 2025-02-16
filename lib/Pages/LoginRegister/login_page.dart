import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'loadingpage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKeyLog = GlobalKey<FormState>();
  final TextEditingController _emailLogController = TextEditingController();
  final TextEditingController _passwordLogController = TextEditingController();
  final FirebaseAuth _authLog = FirebaseAuth.instance;
  final GoogleSignIn _googleSignInLog = GoogleSignIn();
  final FirebaseFirestore dbLog = FirebaseFirestore.instance;
  final emailRegexLog =
      RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
  bool _isLoading = false;

  Future<User?> signInWithGoogle() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignInLog.signIn();
      if (googleUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return null; // User canceled the sign-in
      }

      // Obtain the Google authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with the Google credential
      try {
        final UserCredential userCredential =
            await _authLog.signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user != null) {
          final userDoc = await dbLog.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            print('existing account logging in');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            return user;
          } else {
            print('new account logging in. requiring onboarding');
            await dbLog.collection('users').doc(user.uid).set({
              'email': user.email,
              'uid': user.uid,
              'username': user.displayName,
              'photoURL': user.photoURL,
              'createdAt': FieldValue.serverTimestamp(),
              'creation': user.metadata.creationTime,
              'lastSignIn': user.metadata.lastSignInTime,
            });
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            return user;
          }
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return null;
      } on FirebaseAuthException catch (e) {
        print("Firebase Auth Error Code: ${e.code}"); // Print the error code
        print("Firebase Auth Error Message: ${e.message}");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return null;
      }
    } catch (e) {
      print("Error signing in with Google: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return null;
    }
  }

  @override
  void dispose() {
    _emailLogController.dispose();
    _passwordLogController.dispose();
    super.dispose();
  }

  Future<User?> enterWithOwnCredentials(String email, password) async {
    setState(() {
      _isLoading = true;
    });

    // add a function here to check with firestore first if such account exists before allowing login

    try {
      final UserCredential userCredential = await _authLog
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user != null) {
        print("User debug UID: ${user.uid}");
        print("User debug Email: ${user.email}");
        print("User debug Display Name: ${user.displayName}");
        setState(() {
          _isLoading = false;
        });
        return user;
      } else {
        print("User is NULL after login!"); // VERY IMPORTANT CHECK
        print(user);
        setState(() {
          _isLoading = false;
        });
        return null;
      }
    } catch (e) {
      print("Error signing in with own credentials: $e");
      setState(() {
        _isLoading = false;
      });
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
              color: const Color(0xFF020B40)
                  .withOpacity(0.4), // Adjust opacity as needed
            ),
          ),

          _loginFormContainer(context),

          _isLoading ? const LoadingScreen() : const SizedBox.shrink(),
        ],
      ),
    );
  }

  SingleChildScrollView _loginFormContainer(BuildContext context) {
    return SingleChildScrollView(
      child: Stack(
        children: [
          Center(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.2,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.8,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0XFFF9F9F9),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(50),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Form(
                        key: _formKeyLog,
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
                              'Log In to start Reading!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailLogController,
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
                                if (!emailRegexLog.hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _passwordLogController,
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
                                return null;
                              },
                            ),
                            const SizedBox(height: 5),
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Color(0XFFD4AF37),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 60,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  FocusScope.of(context).unfocus();
                                  if (_formKeyLog.currentState?.validate() ??
                                      false) {
                                    await enterWithOwnCredentials(
                                        _emailLogController.text,
                                        _passwordLogController.text);
                                    // _handleSignInResult(user);
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
                                    'Log In',
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
                            ElevatedButton(
                              onPressed: () async {
                                User? user = await signInWithGoogle();
                                // _handleSignInResult(user);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  'assets/images/google.png',
                                  height: 30,
                                  width: 30,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: AlignmentDirectional.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Don\'t have an account?',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/register');
                                    },
                                    child: const Text(
                                      'Register now',
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
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.12),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.height * 0.2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                      80), // Half of the width/height to make it fully rounded
                  child: Image.asset(
                    'assets/images/nuntium.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
