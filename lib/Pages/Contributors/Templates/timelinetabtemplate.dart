import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Contributors/timelinepage.dart';

class TimelineTab extends StatefulWidget {
  final String? taskId;
  final String? taskTitle;
  final String? taskDescription;

  const TimelineTab({
    super.key,
    required this.taskId,
    required this.taskTitle,
    required this.taskDescription,
  });

  @override
  State<TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends State<TimelineTab> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TimelinePage(
                    taskId: widget.taskId,
                  ),
                ),
              );
            },
            child: Container(
              height: MediaQuery.of(context).size.height * .10,
              width: MediaQuery.of(context).size.width * .75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: const Color.fromARGB(255, 240, 216, 138),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 3),
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
                            const Icon(
                              Icons.access_time,
                              size: 35,
                              color: Color(0XFF020B40),
                            ),
                            const SizedBox(width: 13),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.only(
                                      left: 15, right: 15, top: 3, bottom: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0XFF020B40),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    widget.taskTitle!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * .5,
                                  child: Text(
                                    widget.taskDescription!,
                                    style: const TextStyle(
                                      color: Color(0XFF020B40),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
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
          ),
        ],
      ),
    );
  }
}
