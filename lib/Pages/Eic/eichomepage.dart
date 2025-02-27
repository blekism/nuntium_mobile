import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Eic/sectioncardtemplate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EicHomepage extends StatefulWidget {
  const EicHomepage({super.key});

  @override
  State<EicHomepage> createState() => _EicHomepageState();
}

class _EicHomepageState extends State<EicHomepage> {
  late Stream<QuerySnapshot> sectionsStream;

  @override
  void initState() {
    super.initState();
    sectionsStream =
        FirebaseFirestore.instance.collection('sections').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> sectionsData = [];

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sections',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: sectionsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('An error occurred'),
                  );
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text('No Sections found'),
                  );
                }

                sectionsData =
                    snapshot.data!.docs.map((DocumentSnapshot document) {
                  Map<String, dynamic> data =
                      document.data() as Map<String, dynamic>;
                  data['id'] =
                      document.id; // Add the document ID to the data map
                  return data;
                }).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: sectionsData.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, right: 16.0, bottom: 20),
                      child: SectionCardTemplate(
                        imageAsset: sectionsData[index]['imageAsset']!,
                        isLoading: false,
                        sectionPhoto: sectionsData[index]['sectionPhoto']!,
                        sectionType: sectionsData[index]['sectionType']!,
                        totalMembers: sectionsData[index]['totalMembers']!,
                        totalTask: sectionsData[index]['totalTask']!,
                        sectionID: sectionsData[index]['id']!,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
