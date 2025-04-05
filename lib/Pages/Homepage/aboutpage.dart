import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class AboutUsPage extends ConsumerStatefulWidget {
  const AboutUsPage({super.key});

  @override
  ConsumerState<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends ConsumerState<AboutUsPage> {
  @override
  Widget build(BuildContext context) {
    final memberView = ref.watch(membersProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        appbarTitle: 'About Us',
        hasNavigated: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'The Nuntium',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0XFF020B40),
                  fontFamily: 'RobotoSlab',
                ),
              ),
              const SizedBox(height: 8),
              _divider(context),
              const SizedBox(height: 8),
              const Text(
                'Mission',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0XFF020B40),
                  fontFamily: 'RobotoSlab',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Committed to its mission of truth-telling, The GUIDON seeks to document the existing realities of the Ateneo community and beyond, relaying such experiences through informative reportage and impactful journalistic storytelling. The GUIDON maximizes its print and multimedia platforms for well-researched and timely human-centered narratives. Its outputs directly respond to the current contexts of the university, national,',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0XFF020B40),
                  fontFamily: 'RobotoSlab',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vision',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0XFF020B40),
                  fontFamily: 'RobotoSlab',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The GUIDON is the official student publication of the Ateneo de Manila University. Founded in 1929 by Rev. Frank O’Hara, SJ and first led by Manuel C. Colayco in 1930, it has since been a training ground for countless writers, designers and managers in the practice of responsible journalism.,',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0XFF020B40),
                  fontFamily: 'RobotoSlab',
                ),
              ),
              const SizedBox(height: 8),
              _divider(context),
              const SizedBox(height: 8),
              const Text(
                'Editorial Board',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0XFF020B40),
                  fontFamily: 'RobotoSlab',
                ),
              ),
              const SizedBox(height: 8),
              memberView.when(
                data: (memberView) {
                  if (memberView.isEmpty) {
                    return const Center(
                      child: Text('No Members found'),
                    );
                  }

                  return Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: memberView.length,
                      itemBuilder: (context, index) {
                        final item = memberView[index];

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(item.imageUrl),
                          ),
                          title: Text(item.name),
                          subtitle: Text(item.role),
                        );
                      },
                    ),
                  );
                },
                error: (error, stack) => Center(child: Text('Error: $error')),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container _divider(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: MediaQuery.of(context).size.width * .85,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
