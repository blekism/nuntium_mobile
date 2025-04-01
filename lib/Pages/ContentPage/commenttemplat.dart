import 'Package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Homepage/readhistory.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:shimmer/shimmer.dart';

class CommentTemplate extends StatefulWidget {
  final String? profilePic;
  final String? commenter;
  final String? comment;
  final bool isLoading;
  final bool? isCommentOwner;
  final String? commentId;
  final String? postId;

  const CommentTemplate({
    super.key,
    this.profilePic,
    this.commenter,
    this.comment,
    this.isLoading = false,
    this.isCommentOwner,
    this.commentId,
    this.postId,
  });

  @override
  State<CommentTemplate> createState() => CommentTemplateState();
}

class CommentTemplateState extends State<CommentTemplate> {
  final firebaseFunctions = FirebaseFunctions();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: widget.isLoading
            ? null // No image when loading
            : NetworkImage(widget.profilePic!),
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
      trailing: widget.isCommentOwner == true
          ? PopupMenuButton<String>(
              onSelected: (String value) {
                // Handle the selected option here
                if (value == 'edit') {
                  // Implement edit functionality
                  _showEditDialog(context);
                  print('Edit selected');
                } else if (value == 'delete') {
                  // Implement delete functionality
                  firebaseFunctions.deleteComment(
                    widget.commentId!,
                    widget.postId,
                  );
                  print('Delete selected');
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ];
              },
            )
          : const SizedBox.shrink(),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    String updatedComment = widget.comment ?? '';

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Comment'),
          content: TextField(
            controller: TextEditingController(text: widget.comment),
            onChanged: (value) {
              updatedComment = value;
            },
            decoration:
                const InputDecoration(hintText: 'Enter updated comment'),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Update'),
              onPressed: () async {
                // Call function to update comment in database

                await firebaseFunctions.updateComment(
                  widget.commentId!,
                  updatedComment,
                );

                print('Updated comment: $updatedComment');
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
