import 'package:flutter/material.dart';
import 'CardsTemplate/SeeMorePageTemplate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatefulWidget {
  final String? userRole;
  const HistoryPage({
    super.key,
    this.userRole,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String? _userId;
  final FirebaseAuth _readPostsAuth = FirebaseAuth.instance;
  Stream<QuerySnapshot> readPostsByUserStream =
      const Stream<QuerySnapshot>.empty();
  bool _isLoading = true;

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
              .orderBy('time', descending: true)
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
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching user data')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.userRole != 'none') {
      _getUserId();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Text('Please log in to use this feature'),
      );
    }

    return SeeMorePageTemplate(
      pageName: 'History',
      shownContentStream: readPostsByUserStream,
    );
  }
}
