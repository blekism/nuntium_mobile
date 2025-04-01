import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';
import 'CardsTemplate/seemorepagetemplate.dart';

class TermlyPage extends ConsumerStatefulWidget {
  const TermlyPage({super.key});

  @override
  ConsumerState<TermlyPage> createState() => _TermlyPageState();
}

class _TermlyPageState extends ConsumerState<TermlyPage> {
  @override
  Widget build(BuildContext context) {
    final latesttermlyStream = ref.watch(latestTermlyProvider);
    final alltermlyStream = ref.watch(allTermlyProvider);

    return latesttermlyStream.when(
      data: (latestTermlyData) {
        return alltermlyStream.when(
          data: (allTermlyData) {
            if (allTermlyData.isEmpty && latestTermlyData.isEmpty) {
              return const Center(
                child: Text('No Content Found'),
              );
            }

            return SeeMorePageTemplate(
              pageName: 'Archive',
              shownTopics: allTermlyData,
              termlyFeatured: latestTermlyData,
            );
          },
          error: (error, stackTrace) => Center(child: Text('Error: $error')),
          loading: () => const Center(child: CircularProgressIndicator()),
        );
      },
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}
