import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/ContentPage/articlepage.dart';
import 'package:nuntium_mobile/Pages/Homepage/aaaapdf.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/providers/read_provider.dart';
import 'package:shimmer/shimmer.dart';

class FeaturedPostCard extends ConsumerWidget {
  final String? imageAsset;
  final String? sectionType;
  final String? articleTitle;
  final String? timePosted;
  final String? postID;
  final bool isLoading;
  final bool? isAuthenticated;
  final bool isTermly;
  final String? pdfUrl;

  FeaturedPostCard({
    super.key,
    this.imageAsset,
    this.sectionType,
    this.articleTitle,
    this.timePosted,
    this.postID,
    this.isLoading = false,
    this.isAuthenticated,
    required this.isTermly,
    this.pdfUrl,
  });

  final firebaseFunctions = FirebaseFunctions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isRead;
    if (firebaseFunctions.auth.currentUser != null) {
      final readStatus = ref.watch(savedPostsProvider);
      isRead = readStatus.contains(postID);
    } else {
      isRead = false;
    }

    return GestureDetector(
      onTap: isLoading
          ? null
          : isTermly != true
              ? () {
                  final notifier = ref.read(savedPostsProvider.notifier);
                  print('Navigating to content page from featured');
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ArticlePage(
                                postId: postID!,
                              )));
                  isAuthenticated == true
                      ? notifier.markAsRead(postID!, isLoading)
                      : null;
                }
              : () {
                  final notifier = ref.read(savedPostsProvider.notifier);
                  print('Navigating to content page from featured');
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PdfViewerScreen(
                                pdfUrl: pdfUrl!,
                              )));
                  isAuthenticated == true
                      ? notifier.markAsRead(postID!, isLoading)
                      : null;
                },
      child: Container(
        width: MediaQuery.of(context).size.width * .8,
        height: MediaQuery.of(context).size.height * .35,
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
              : _buildContent(context, isRead),
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
  Widget _buildContent(BuildContext context, bool isRead) {
    final screenWidth = MediaQuery.of(context).size.width; // Get screen width
    final titleFontSmall = (screenWidth * 0.06).clamp(11.0, 13.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(
            imageAsset!,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                  color: Colors.grey[200]); // Placeholder if image fails
            },
          ),
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
                  style: TextStyle(
                    color: isRead ? Colors.grey[400] : Colors.white,
                    fontSize: titleFontSmall,
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
                    style: TextStyle(
                      color: isRead ? Colors.grey[400] : Colors.white,
                      fontSize: titleFontSmall,
                      fontWeight: FontWeight.w600,
                    ),
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    timePosted!,
                    style: TextStyle(
                      color: isRead
                          ? Colors.grey[400]
                          : Colors.white.withValues(alpha: 0.3),
                      fontSize: titleFontSmall,
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
