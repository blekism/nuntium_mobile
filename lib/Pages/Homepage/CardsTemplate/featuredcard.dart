import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeaturedPostCard extends StatelessWidget {
  final String? imageAsset;
  final String? sectionType;
  final String? articleTitle;
  final String? timePosted;
  final String? postID;
  final bool isLoading;

  const FeaturedPostCard({
    super.key,
    this.imageAsset,
    this.sectionType,
    this.articleTitle,
    this.timePosted,
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
        'isRead': true,
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
              print('Navigating to content page from featured');
              _handlePostClick(context);
              Navigator.pushNamed(context, '/contentpage', arguments: {
                'postID': postID,
              });
            },
      child: Container(
        width: MediaQuery.of(context).size.width * .8,
        height: MediaQuery.of(context).size.height * .2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 5.0,
              spreadRadius: 0.0,
              offset: Offset(1.0, 1.0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: isLoading
              ? _buildShimmerEffect() // Show shimmer when loading
              : _buildContent(),
        ),
      ),
    );
  }

  /// **🔹 Shimmer Effect Placeholder**
  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simulating the section type label
            Container(
              width: 80,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Simulating the article title
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 5),
            // Simulating the time posted
            Container(
              width: 100,
              height: 15,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **🔹 Actual Content**
  Widget _buildContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        Image.network(
          imageAsset!,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            return Container(
                color: Colors.grey[200]); // Placeholder if image fails
          },
        ),
        // Overlay for readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
        // Content
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Type Label
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0XFF020B40),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.grey,
                      blurRadius: 5.0,
                      spreadRadius: 0.0,
                      offset: Offset(1.0, 1.0),
                    ),
                  ],
                ),
                child: Text(
                  sectionType!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              // Article Title & Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    articleTitle!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    timePosted!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }
}
