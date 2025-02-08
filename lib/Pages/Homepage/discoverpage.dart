import 'package:flutter/material.dart';
import 'CardsTemplate/SeeMorePageTemplate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final Stream<QuerySnapshot> discoverStream = FirebaseFirestore.instance
      .collection('posts')
      .where('appearIn', isEqualTo: 'general')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return SeeMorePageTemplate(
      pageName: 'Discover',
      shownContentStream: discoverStream,
    );
  }
}
