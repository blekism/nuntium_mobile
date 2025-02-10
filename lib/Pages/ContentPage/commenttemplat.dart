import 'Package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CommentTemplate extends StatefulWidget {
  final String profilePic;
  final String commenter;
  final String comment;
  final bool isLoading;

  const CommentTemplate({
    super.key,
    required this.profilePic,
    required this.commenter,
    required this.comment,
    this.isLoading = false,
  });

  @override
  State<CommentTemplate> createState() => CommentTemplateState();
}

class CommentTemplateState extends State<CommentTemplate> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: widget.isLoading
            ? null // No image when loading
            : AssetImage('assets/images/nudasma.jpg'),
        child: widget.isLoading
            ? Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      ),
      title: widget.isLoading
          ? Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 16,
                width: 100,
                color: Colors.white,
              ),
            )
          : Text(widget.commenter ?? 'Unknown User'),
      subtitle: widget.isLoading
          ? Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 14,
                width: 150,
                color: Colors.white,
              ),
            )
          : Text(widget.comment ?? 'No comment'),
    );
  }
}
