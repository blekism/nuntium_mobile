import 'package:flutter/material.dart';
import 'CardsTemplate/SeeMorePageTemplate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  String? _userId;
  final FirebaseAuth _savedPostsAuth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> savedPostsByUserStream;
  bool _isLoading = true;

  Future<void> _getUserId() async {
    try {
      final User? user = _savedPostsAuth.currentUser;

      if (user != null) {
        setState(() {
          _userId = user.uid;
          savedPostsByUserStream = FirebaseFirestore.instance
              .collection('users')
              .doc(_userId)
              .collection('savedPosts')
              .where('isSaved', isEqualTo: true)
              .snapshots();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
    } catch (e) {
      print('error getting user id ${e}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching user data')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SeeMorePageTemplate(
      pageName: 'Saved Posts',
      shownContentStream: savedPostsByUserStream,
    );
  }
}
