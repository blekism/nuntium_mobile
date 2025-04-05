import 'package:flutter/material.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

class ParentTopicCard extends StatefulWidget {
  final String id;
  final String topicTitle;
  final String section;
  final String status;
  final String deadline;
  final String priority;
  final int totalSubtask;
  final int completedSubtask;
  final String member1, member2;
  final int otherMembers;

  const ParentTopicCard({
    super.key,
    required this.id,
    required this.topicTitle,
    required this.section,
    required this.status,
    required this.deadline,
    required this.priority,
    required this.totalSubtask,
    required this.completedSubtask,
    required this.member1,
    required this.member2,
    this.otherMembers = 0,
  });

  @override
  State<ParentTopicCard> createState() => _ParentTopicCardState();
}

class _ParentTopicCardState extends State<ParentTopicCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * .9,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(60), // Shadow color
            spreadRadius: 2, // Spread radius
            blurRadius: 5, // Blur radius
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              widget.topicTitle,
              // widget.otherMembers.toString(),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                child: Row(
                  children: [
                    widget.member1 != ''
                        ? CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(widget.member1),
                          )
                        : const CircleAvatar(
                            radius: 13,
                            backgroundImage:
                                AssetImage('assets/images/nudasma.jpg'),
                          ),
                    const SizedBox(width: 4),
                    widget.member2 != ''
                        ? CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(widget.member2),
                          )
                        : const CircleAvatar(
                            radius: 13,
                            backgroundImage:
                                AssetImage('assets/images/nudasma.jpg'),
                          ),
                    const SizedBox(width: 4),
                    widget.otherMembers > 0
                        ? CircleAvatar(
                            radius: 13,
                            backgroundColor: Colors.white,
                            child: Text(
                              '+${widget.otherMembers}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDE4FB),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          widget.section,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF020B40), // dark navy text color
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDE4FB),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          widget.status,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF020B40), // dark navy text color
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDE4FB),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          widget.deadline,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF020B40), // dark navy text color
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDE4FB),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          widget.priority,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF020B40), // dark navy text color
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          StepProgressIndicator(
            totalSteps: 6,
            currentStep: widget.completedSubtask,
            selectedColor: const Color(0XFF020B40),
            unselectedColor: const Color(0XFF020B40).withAlpha(90),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${widget.completedSubtask} of ${widget.totalSubtask} Tasks Done!',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
