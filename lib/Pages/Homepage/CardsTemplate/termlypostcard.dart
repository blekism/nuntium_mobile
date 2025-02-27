import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Termlypostcard extends StatefulWidget {
  final bool isLoading;
  final String? termlyCover;
  final String? title;
  final String? termlyType;

  const Termlypostcard({
    super.key,
    this.isLoading = false,
    this.termlyCover,
    this.title,
    this.termlyType,
  });

  @override
  State<Termlypostcard> createState() => _TermlypostcardState();
}

class _TermlypostcardState extends State<Termlypostcard> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.grey,
              blurRadius: 10,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: widget.isLoading
              ? _buildShimmerEffect() // Show shimmer when loading
              : _buildContent(),
        ),
      ),
    );
  }

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
              width: 90,
              height: 40,
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

  Widget _buildContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        Image.network(
          widget.termlyCover!,
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
                  widget.title!,
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
                    widget.termlyType!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
