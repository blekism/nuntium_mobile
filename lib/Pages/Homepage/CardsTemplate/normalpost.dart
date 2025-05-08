import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/ContentPage/articlepage.dart';
import 'package:nuntium_mobile/Pages/ContentPage/photojournpage.dart';
import 'package:nuntium_mobile/Pages/Homepage/aaaapdf.dart';
import 'package:nuntium_mobile/providers/read_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nuntium_mobile/firebase_functions.dart';

class NormalPostCard extends ConsumerWidget {
  final String? imageAsset;
  final String? sectionType;
  final String? articleTitle;
  final String? datePosted;
  final String? postID;
  final bool isLoading;
  final bool? isAuthenticated;
  final String? pdfUrl;
  final String? forPage;
  final bool isPosted;

  NormalPostCard({
    super.key,
    this.imageAsset,
    this.sectionType,
    this.articleTitle,
    this.datePosted,
    this.postID,
    this.isLoading = false,
    this.isAuthenticated,
    this.pdfUrl,
    required this.forPage,
    required this.isPosted,
  });

  final firebaseFunctions = FirebaseFunctions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isRead;
    final cardWidth = MediaQuery.of(context).size.width * .90;
    if (firebaseFunctions.auth.currentUser != null) {
      final readStatus = ref.watch(savedPostsProvider);
      isRead = readStatus.contains(postID);
    } else {
      isRead = false;
    }

    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              // Start of onTap logic
              final notifier = ref.read(savedPostsProvider.notifier);
              switch (forPage) {
                case 'article':
                  print('Navigating to content page from normal (article)');
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ArticlePage(
                                postId: postID!,
                                isPosted: isPosted,
                              )));
                  if (isAuthenticated == true &&
                      postID != null &&
                      isPosted == true) {
                    notifier.markAsRead(postID!, isLoading);
                  }
                  break; // Don't forget break!
                case 'termly':
                  print('Navigating to PDF viewer from normal (termly)');
                  // Ensure pdfUrl is not null before navigating
                  if (pdfUrl != null) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PdfViewerScreen(
                                  pdfUrl: pdfUrl!,
                                  isPosted: isPosted,
                                  postId: postID!,
                                )));
                    if (isAuthenticated == true &&
                        postID != null &&
                        isPosted == true) {
                      notifier.markAsRead(postID!, isLoading);
                    }
                  } else {
                    print('Error: pdfUrl is null for termly post $postID');
                    // Optionally show a snackbar or message to the user
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Could not open PDF: URL missing.')));
                  }
                  break; // Don't forget break!
                case 'photography':
                  print('Photography post tapped. Post ID: $postID');
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PhotoJournPage(
                                postId: postID!,
                                isPosted: isPosted,
                              )));
                  if (isAuthenticated == true &&
                      postID != null &&
                      isPosted == true) {
                    notifier.markAsRead(postID!, isLoading);
                  }
                  break; // Don't forget break!
                default:
                  print('Unknown page type: $forPage');
                // Handle unexpected cases or do nothing
              }
            },
      child: Container(
        width: cardWidth,
        // height: MediaQuery.of(context).size.height * .15,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: isLoading
              ? _buildShimmerEffect(context)
              : _buildContent(context, cardWidth, isRead),
        ),
      ),
    );
  }

  /// **🔹 Actual Content**
  Widget _buildContent(BuildContext context, double cardWidth, bool isRead) {
    final titleFontSmall = (cardWidth * 0.04).clamp(10.0, 13.0);
    final Color readColor = Colors.grey[600]!; // Dimmer color for read items
    const Color unreadColor = Colors.black;
    final Color readMetaColor =
        Colors.grey[500]!; // Slightly dimmer grey for read meta
    const Color unreadMetaColor = Colors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(
            imageAsset ??
                'https://firebasestorage.googleapis.com/v0/b/nu-publication-system.firebasestorage.app/o/logo.jpg?alt=media&token=fed28218-248d-4ad9-a639-14f072f7e9b9',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width * .33,
            height: MediaQuery.of(context).size.height * .15,
            errorBuilder: (context, error, stackTrace) => Container(
              // Fallback for image error
              width: MediaQuery.of(context).size.width * .33,
              height: MediaQuery.of(context).size.height * .15,
              color: Colors.grey[200],
              child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
            ),
            loadingBuilder: (context, child, loadingProgress) {
              // Loading indicator for image
              if (loadingProgress == null) return child;
              return Container(
                width: MediaQuery.of(context).size.width * .33,
                height: MediaQuery.of(context).size.height * .15,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2.0,
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          // Use Expanded to prevent overflow if text is long
          child: Padding(
            padding: const EdgeInsets.only(
                left: 9, right: 9, top: 9, bottom: 9), // Adjusted padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
              children: [
                Text(
                  sectionType ?? 'Unknown Section', // Provide default
                  style: TextStyle(
                    color: isRead ? readMetaColor : unreadMetaColor,
                    fontSize: titleFontSmall,
                    fontWeight: FontWeight.w500,
                    fontStyle: isRead ? FontStyle.italic : FontStyle.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  articleTitle ?? 'Untitled Article', // Provide default
                  style: TextStyle(
                    color: isRead ? readColor : unreadColor,
                    fontSize: titleFontSmall,
                    fontWeight: FontWeight.w700,
                    fontStyle: isRead ? FontStyle.italic : FontStyle.normal,
                  ),
                  maxLines: 3, // Allow more lines for title
                  overflow:
                      TextOverflow.ellipsis, // Add ellipsis if title overflows
                ),
                const SizedBox(height: 5), // Increased spacing
                Text(
                  datePosted ?? 'Date Unknown', // Provide default
                  style: TextStyle(
                    color: isRead ? readMetaColor : unreadMetaColor,
                    fontSize: titleFontSmall * 0.9, // Slightly smaller date
                    fontWeight: FontWeight.w400,
                    fontStyle: isRead ? FontStyle.italic : FontStyle.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        )
      ],
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
            height: MediaQuery.of(context).size.height * .15,
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
}
