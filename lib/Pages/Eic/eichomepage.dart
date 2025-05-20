import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/Eic/sectioncardtemplate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class EicHomepage extends ConsumerStatefulWidget {
  const EicHomepage({super.key});

  @override
  ConsumerState<EicHomepage> createState() => _EicHomepageState();
}

class _EicHomepageState extends ConsumerState<EicHomepage> {
  @override
  Widget build(BuildContext context) {
    final sectionView = ref.watch(sectionProvider);

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: sectionView.when(
              data: (QuerySnapshot section) {
                if (section.docs.isEmpty) {
                  return const Center(
                    child: Text('No Sections Found'),
                  );
                }

                return ListView.builder(
                    shrinkWrap: true,
                    itemCount: section.docs.length,
                    itemBuilder: (context, index) {
                      final sectionDoc = section.docs[index];

                      final sectionData =
                          sectionDoc.data() as Map<String, dynamic>?;

                      if (sectionData != null) {
                        return Padding(
                          padding: const EdgeInsets.only(
                              left: 16.0, right: 16.0, bottom: 20),
                          child: SectionCardTemplate(
                            imageAsset: sectionData['imageAsset']!,
                            isLoading: false,
                            sectionPhoto: sectionData['sectionPhoto']!,
                            sectionType: sectionData['sectionType']!,
                            totalMembers: sectionData['totalMembers']!,
                            totalTask: sectionData['totalTask']!,
                          ),
                        );
                      } else {
                        return const Center(
                          child: Text('Error loading section data'),
                        );
                      }
                    });
              },
              error: (error, stack) => Center(child: Text('Error: $error')),
              loading: () => const SectionCardTemplate(isLoading: true),
            ),
          )
        ],
      ),
    );
  }
}
