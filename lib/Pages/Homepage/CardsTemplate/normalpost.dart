import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/ContentPage/articlepage.dart';
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
  final bool isTermly;
  final String? pdfUrl;

  NormalPostCard({
    super.key,
    this.imageAsset,
    this.sectionType,
    this.articleTitle,
    this.datePosted,
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
          : isTermly != true
              ? () {
                  print('Navigating to content page from normal');
                  final notifier = ref.read(savedPostsProvider.notifier);
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
                  print('Navigating to content page from normal');
                  final notifier = ref.read(savedPostsProvider.notifier);
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
        width: cardWidth,
        // height: MediaQuery.of(context).size.height * .15,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: isRead ? Colors.blue.withValues(alpha: 0.2) : Colors.white,
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
              : _buildContent(context, cardWidth),
        ),
      ),
    );
  }

  /// **🔹 Actual Content**
  Widget _buildContent(BuildContext context, double cardWidth) {
    final titleFontSmall = (cardWidth * 0.04).clamp(10.0, 13.0);

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
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                sectionType ?? 'unknown',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: titleFontSmall,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                width: MediaQuery.of(context).size.width * .40,
                child: Text(
                  articleTitle ?? 'unkown',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: titleFontSmall,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                datePosted ?? 'unknown',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: titleFontSmall,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
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
