import 'package:flutter/material.dart';
import 'CardsTemplate/SeeMorePageTemplate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TermlyPage extends StatefulWidget {
  const TermlyPage({super.key});

  @override
  State<TermlyPage> createState() => _TermlyPageState();
}

class _TermlyPageState extends State<TermlyPage> {
  final Stream<QuerySnapshot> archiveStream = FirebaseFirestore.instance
      .collection('posts')
      .where('isTermly', isEqualTo: true)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return SeeMorePageTemplate(
      pageName: 'Archive',
      shownContentStream: archiveStream,
    );
  }
}
