import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';
import 'CardsTemplate/SeeMorePageTemplate.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseFunctions = FirebaseFunctions();

class HistoryPage extends ConsumerStatefulWidget {
  final String? userRole;
  const HistoryPage({
    super.key,
    this.userRole,
  });

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  User? user = firebaseFunctions.auth.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(
        child: Text('Please log in to use this feature'),
      );
    } else {
      final reditPage = ref.watch(reditContentProvider(user!.uid));

      return Scaffold(
        appBar: const CustomAppBar(
          appbarTitle: 'Read History',
          hasNavigated: false,
        ),
        body: reditPage.when(
          data: (reditPage) {
            if (reditPage.isEmpty) {
              return const Center(child: Text('Start reading now!'));
            }

            return SeeMorePageTemplate(
              pageName: 'History',
              shownTopics: reditPage,
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Center(
            child: Text('Error: $error'),
          ),
        ),
      );
    }
  }
}
