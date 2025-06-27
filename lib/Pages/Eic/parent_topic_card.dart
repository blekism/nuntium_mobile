import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Eic/single_topic_view.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

class ParentTopicCard extends StatefulWidget {
  final String id;
  final String topicTitle;
  final String section;
  final String status;
  final String deadline;
  final int totalSubtask;
  final int completedSubtask;
  final String member1, member2;
  final int otherMembers;
  final int projectStep;
  final bool isLoading;

  const ParentTopicCard({
    super.key,
    required this.id,
    required this.topicTitle,
    required this.section,
    required this.status,
    required this.deadline,
    required this.totalSubtask,
    required this.completedSubtask,
    required this.member1,
    required this.member2,
    this.otherMembers = 0,
    required this.projectStep,
    this.isLoading = false,
  });

  @override
  State<ParentTopicCard> createState() => _ParentTopicCardState();
}

class _ParentTopicCardState extends State<ParentTopicCard> {
  bool isBeingDeleted = false;
  final firebaseFunctions = FirebaseFunctions();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TopicSingleRead(
              id: widget.id,
              section: widget.section,
              member1: widget.member1,
              member2: widget.member2,
              otherMember: widget.otherMembers,
              status: widget.status,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          widget.topicTitle,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Align(
                      alignment: Alignment.topRight,
                      child: PopupMenuButton<String>(
                        // Specify the type of the menu items' value
                        icon: const Icon(Icons.more_horiz_rounded),
                        onSelected: (String value) async {
                          if (value == 'delete') {
                            bool? confirmed = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: const Text(
                                      'Are you sure you want to delete this?'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.of(context)
                                          .pop(false), // No
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop(true);
                                        setState(() {
                                          isBeingDeleted = true;
                                        });
                                        await firebaseFunctions
                                            .deleteTopic(widget.id);
                                      }, // Yes
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmed == true) {
                              print('Delete confirmed');
                              // Implement your delete functionality here
                            } else {
                              print('Delete cancelled');
                              // User cancelled the delete operation
                            }
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ];
                        },
                      ),
                    ),
                  ],
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      Color(0xFF020B40), // dark navy text color
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      Color(0xFF020B40), // dark navy text color
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: MediaQuery.of(context).size.width * .4,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA3A3A3),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                offset: const Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Due at: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.center,
                                  child: Text(
                                    widget.deadline,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 10),
                StepProgressIndicator(
                  totalSteps: 14,
                  currentStep: widget.projectStep,
                  selectedColor: const Color(0XFF020B40),
                  unselectedColor: const Color(0XFF0E0E0E).withAlpha(90),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Topic Progress',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${widget.projectStep} of 14 Steps Done!',
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
          ),
          Visibility(
            visible: isBeingDeleted,
            child: Positioned.fill(
              child: Container(
                color:
                    Colors.black.withOpacity(0.3), // Slightly transparent black
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
