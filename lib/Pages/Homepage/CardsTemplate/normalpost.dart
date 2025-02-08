import 'package:flutter/material.dart';

class NormalPostCard extends StatelessWidget {
  final String imageAsset;
  final String sectionType;
  final String articleTitle;
  final String datePosted;
  final String postID;

  const NormalPostCard(
      {super.key,
      required this.imageAsset,
      required this.sectionType,
      required this.articleTitle,
      required this.datePosted,
      required this.postID});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('papunta na sa content page from normal');

        Navigator.pushNamed(context, '/contentpage', arguments: {
          'postID': postID,
        });
      },
      child: Container(
        width: MediaQuery.of(context).size.width * .90,
        height: MediaQuery.of(context).size.height * .15,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white.withOpacity(0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Row(
            // mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  imageAsset, // Use the provided imageAsset
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  width: MediaQuery.of(context).size.width * .33,
                  height: MediaQuery.of(context).size.height * .3,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      sectionType,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      articleTitle,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const SizedBox(width: 10),
                    Text(
                      datePosted,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
