import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';
import 'CardsTemplate/SeeMorePageTemplate.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseFunctions = FirebaseFunctions();

class SavedPage extends ConsumerStatefulWidget {
  final String? userRole;
  const SavedPage({
    super.key,
    this.userRole,
  });

  @override
  ConsumerState<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends ConsumerState<SavedPage> {
  User? currentUser = firebaseFunctions.auth.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(
        child: Text('Please log in to use this feature'),
      );
    }
    final bookmarkedStream =
        ref.watch(bookmarkContentProvider(currentUser!.uid));

    return bookmarkedStream.when(
      data: (bookmarkedStream) {
        if (bookmarkedStream.isEmpty) {
          return const Center(child: Text('Start bookmarking items now! hehe'));
        }

        return SeeMorePageTemplate(
          pageName: 'Saved Posts',
          shownTopics: bookmarkedStream,
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackStrace) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
