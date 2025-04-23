import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Eic/topicpage.dart';
import 'package:shimmer/shimmer.dart';

class SectionCardTemplate extends StatelessWidget {
  final bool isLoading;
  final String? imageAsset;
  final String? sectionType;
  final String? totalTask;
  final String? sectionID;
  final String? totalMembers;
  final String? sectionPhoto;

  const SectionCardTemplate({
    super.key,
    this.isLoading = false,
    this.imageAsset,
    this.sectionType,
    this.totalTask,
    this.sectionID,
    this.totalMembers,
    this.sectionPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('section name and id is: $sectionID and $sectionType');
        print('Section clicked');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TopicPage(
              sectionID: sectionID,
              sectionName: sectionType,
              secEd: true,
              shouldShowAppbar: true,
            ),
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * .85,
        height: MediaQuery.of(context).size.height * .25,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              blurRadius: 5.0,
              spreadRadius: 0.0,
              offset: Offset(1.0, 1.0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: isLoading
              ? _buildShimmerEffect() // Show shimmer when loading
              : _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simulating the section type label
            Container(
              width: 85,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Simulating the article title
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 5),
            // Simulating the time posted
            Container(
              width: 100,
              height: 15,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Center(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            sectionPhoto!,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withAlpha(100),
                  const Color(0XFF020B40).withAlpha(100),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * .12,
                  height: MediaQuery.of(context).size.height * .06,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 5.0,
                        spreadRadius: 0.0,
                        offset: Offset(1.0, 1.0),
                      ),
                    ],
                  ),
                  child: Image.network(
                    imageAsset!,
                    fit: BoxFit.contain,
                    height: 10,
                    width: 10,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  sectionType!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${totalMembers!} Members',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: MediaQuery.of(context).size.height * .006,
                  width: MediaQuery.of(context).size.width * .6,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0XFFD4AF37),
                      Color(0XFF020B40),
                    ]),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '${totalTask!} Tasks',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
