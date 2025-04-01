import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';
import 'CardsTemplate/SeeMorePageTemplate.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  @override
  Widget build(BuildContext context) {
    final discoverStream = ref.watch(discoverContentProvider);

    return discoverStream.when(
      data: (discoverStream) {
        if (discoverStream.isEmpty) {
          return const Center(child: Text('No Articles available'));
        }
        return SeeMorePageTemplate(
          pageName: 'Discover',
          shownTopics: discoverStream,
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
