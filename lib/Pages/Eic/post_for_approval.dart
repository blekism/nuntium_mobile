import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/Homepage/CardsTemplate/normalpost.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class PostForApproval extends ConsumerStatefulWidget {
  const PostForApproval({super.key});

  @override
  ConsumerState<PostForApproval> createState() => _PostForApprovalState();
}

class _PostForApprovalState extends ConsumerState<PostForApproval> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final postApprovalsView = ref.watch(postsForApprovalProvider);
    User? currentUser = _auth.currentUser;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: postApprovalsView.when(
              data: (postApproval) {
                if (postApproval.isEmpty) {
                  return const Center(child: Text('No normal items available'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: postApproval.length,
                  itemBuilder: (context, index) {
                    final item = postApproval[index];
                    return Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, right: 16.0, bottom: 16),
                      child: NormalPostCard(
                        imageAsset: item.imageUrl[0],
                        sectionType: item.section,
                        articleTitle: item.title,
                        postID: item.id,
                        isAuthenticated: currentUser != null,
                        datePosted: item.datePosted,
                        isLoading: false,
                        forPage: item.pageType,
                        isPosted: item.isPosted,
                        pdfUrl: item.pdfUrl,
                      ),
                    );
                  },
                );
              },
              error: (error, stack) => Center(child: Text('Error: $error')),
              loading: () => SizedBox(
                height: MediaQuery.of(context).size.height * .15,
                child: NormalPostCard(
                  isLoading: true,
                  forPage: '',
                  isPosted: false,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
