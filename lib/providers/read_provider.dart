import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class SavedPostsNotifier extends AutoDisposeNotifier<Set<String>> {
  final FirebaseFunctions firebaseFunctions;

  SavedPostsNotifier(this.firebaseFunctions);

  @override
  Set<String> build() {
    if (firebaseFunctions.auth.currentUser != null) {
      String userId = firebaseFunctions.auth.currentUser!.uid;
      firebaseFunctions.readPostsList(userId).listen((postIds) {
        state = postIds;
      });
    } else {
      return {};
    }

    return {};
  }

  void markAsRead(String postId, bool isLoading) {
    if (firebaseFunctions.auth.currentUser != null) {
      firebaseFunctions.handlePostClick(postId, isLoading);
      if (!state.contains(postId)) {
        state = {...state, postId};
      }
    } else {
      // Handle case where user is not logged in (optional)
      print("Cannot mark as read, no user logged in.");
    }
  }
}

final savedPostsProvider =
    NotifierProvider.autoDispose<SavedPostsNotifier, Set<String>>(
  () => SavedPostsNotifier(firebaseFunctions),
);
