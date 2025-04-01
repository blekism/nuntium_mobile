import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/ContentPage/commenttemplat.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class CommentSheetV2 extends ConsumerStatefulWidget {
  final String postId;

  const CommentSheetV2({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<CommentSheetV2> createState() => _CommentSheetV2State();
}

class _CommentSheetV2State extends ConsumerState<CommentSheetV2> {
  final commentController = TextEditingController();
  bool isTextNotEmpty = false;

  @override
  Widget build(BuildContext context) {
    final showComments = ref.watch(commentsContentProvider(widget.postId));

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        commentController.addListener(() {
          setModalState(() {
            isTextNotEmpty = commentController.text.trim().isNotEmpty;
          });
        });

        return Stack(
          children: [
            FractionallySizedBox(
              heightFactor: .75,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        child: showComments.when(
                          data: (showComments) {
                            if (showComments.isEmpty) {
                              return const Center(
                                child: Text('Be the first one to comment!'),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: showComments.length,
                              itemBuilder: (context, index) {
                                final item = showComments[index];

                                return CommentTemplate(
                                  profilePic: item.imageUrl,
                                  comment: item.comment,
                                  commenter: item.commenter,
                                  isLoading: false,
                                  isCommentOwner: item.userId ==
                                      FirebaseAuth.instance.currentUser!.uid,
                                  commentId: item.commentId,
                                  postId: widget.postId,
                                );
                              },
                            );
                          },
                          error: (error, stack) =>
                              Center(child: Text('Error: $error')),
                          loading: () => const CommentTemplate(
                            isLoading: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: Colors.black,
                          width: 1.0,
                        ),
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context)
                              .viewInsets
                              .bottom, // Adjust based on keyboard
                          left: 8,
                          right: 8,
                          top: 10,
                        ),
                        child: TextField(
                          controller: commentController,
                          cursorColor: Colors.black,
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  const BorderSide(color: Colors.black45),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.send,
                                  color: isTextNotEmpty
                                      ? Colors.blue
                                      : Colors.grey),
                              onPressed: isTextNotEmpty
                                  ? () async {
                                      // Call function to send comment
                                      await firebaseFunctions.insertComment(
                                        commentController.text,
                                        widget.postId,
                                      );

                                      commentController.clear();
                                    }
                                  : null, // Disable button if text is empty
                            ),
                          ),

                          keyboardType: TextInputType.multiline,
                          maxLines: null, // Allow multiple lines if needed
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
