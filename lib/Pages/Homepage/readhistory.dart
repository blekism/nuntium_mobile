import 'package:flutter/material.dart';
import 'CardsTemplate/SeeMorePageTemplate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String? _userId;
  final FirebaseAuth _readPostsAuth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> readPostsByUserStream;

  Future<void> _getUserId() async {
    try {
      final User? user = _readPostsAuth.currentUser;

      if (user != null) {
        setState(() {
          _userId = user.uid;
          readPostsByUserStream = FirebaseFirestore.instance
              .collection('users')
              .doc(_userId)
              .collection('savedPosts')
              .where('isRead', isEqualTo: true)
              .where('postId', isNotEqualTo: null)
              .snapshots();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
    } catch (e) {
      print('error getting user id ${e}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching user data')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  @override
  Widget build(BuildContext context) {
    return SeeMorePageTemplate(
      pageName: 'History',
      shownContentStream: readPostsByUserStream,
    );
  }
}
