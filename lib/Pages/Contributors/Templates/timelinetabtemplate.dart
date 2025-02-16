import 'package:flutter/material.dart';

class TimelineTab extends StatefulWidget {
  const TimelineTab({super.key});

  @override
  State<TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends State<TimelineTab> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * .12,
            width: MediaQuery.of(context).size.width * .75,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: const Color.fromARGB(255, 240, 216, 138),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // Replacing the image with a clock icon
                          const Icon(
                            Icons.access_time, // Clock icon
                            size: 35,
                            color: Color(0XFF020B40), // Matching the text color
                          ),
                          const SizedBox(width: 13),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.only(
                                    left: 15,
                                    right: 15,
                                    top: 3,
                                    bottom:
                                        3), // Optional: Add padding to the container
                                decoration: BoxDecoration(
                                  color: const Color(
                                      0XFF020B40), // Set the background color to blue
                                  borderRadius: BorderRadius.circular(
                                      15), // Set border radius for rounded corners
                                ),
                                child: const Text(
                                  'Task Title',
                                  style: TextStyle(
                                    color:
                                        Colors.white, // Set text color to white
                                    fontSize: 13,
                                    fontWeight: FontWeight
                                        .w600, // Set font weight to w600
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * .5,
                                child: const Text(
                                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                                  style: TextStyle(
                                    color: Color(0XFF020B40),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow:
                                      TextOverflow.ellipsis, // Prevent overflow
                                  maxLines: 2, // Limit to 2 lines for this text
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Image.asset(
                        'assets/images/forward.png',
                        width: 35,
                        height: 35,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
