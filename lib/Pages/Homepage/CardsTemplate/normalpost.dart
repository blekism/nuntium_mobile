import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NormalPostCard extends StatelessWidget {
  final String? imageAsset;
  final String? sectionType;
  final String? articleTitle;
  final String? datePosted;
  final String? postID;
  final bool isLoading;

  const NormalPostCard({
    super.key,
    this.imageAsset,
    this.sectionType,
    this.articleTitle,
    this.datePosted,
    this.postID,
    this.isLoading = false,
  });

  Future<void> _handlePostClick(BuildContext context) async {
    if (isLoading) return;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print("User not logged in");
        return;
      }

      String userID = user.uid;
      String? postIDRef = postID;

      if (postIDRef == null) {
        print("Error: Post ID is null");
        return;
      }

      // Reference Firestore collection
      DocumentReference historyRef =
          FirebaseFirestore.instance.collection('posts').doc(postIDRef);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .collection('savedPosts')
          .add({
        'postId': historyRef,
        'isRead': true, // Store post reference
        'time': Timestamp.now(),
      });
      print("Post saved to history");

      // Navigate to content page
    } catch (e) {
      print("Error saving post: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              print('Navigating to content page from normal');
              _handlePostClick(context);
              Navigator.pushNamed(
                context,
                '/contentpage',
                arguments: {
                  'postID': postID,
                },
              );
            },
      child: Container(
        width: MediaQuery.of(context).size.width * .90,
        height: MediaQuery.of(context).size.height * .15,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white.withOpacity(0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child:
              isLoading ? _buildShimmerEffect(context) : _buildContent(context),
        ),
      ),
    );
  }

  /// **🔹 Shimmer Effect Placeholder**
  Widget _buildShimmerEffect(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * .33,
            height: MediaQuery.of(context).size.height * .3,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 80, height: 14, color: Colors.white),
              const SizedBox(height: 9),
              Container(width: 150, height: 16, color: Colors.white),
              const SizedBox(height: 5),
              Container(width: 100, height: 12, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  /// **🔹 Actual Content**
  Widget _buildContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(
            imageAsset!,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width * .33,
            height: MediaQuery.of(context).size.height * .3,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sectionType!,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                articleTitle!,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                datePosted!,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
