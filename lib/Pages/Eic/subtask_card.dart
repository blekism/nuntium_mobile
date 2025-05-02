import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Eic/do_assigned_task.dart';
import 'package:nuntium_mobile/firebase_functions.dart';

class SubtaskCard extends StatefulWidget {
  final String imageurl,
      id,
      title,
      section,
      type,
      deadline,
      status,
      topicId,
      sectionId;

  const SubtaskCard({
    super.key,
    required this.id,
    required this.title,
    required this.imageurl,
    required this.section,
    required this.type,
    required this.deadline,
    required this.status,
    required this.topicId,
    required this.sectionId,
  });

  @override
  State<SubtaskCard> createState() => _SubtaskCardState();
}

class _SubtaskCardState extends State<SubtaskCard> {
  final firebaseFunctions = FirebaseFunctions();
  bool isBeingDeleted = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoAssignedTaskPage(
              section: widget.section,
              taskId: widget.id,
              topicId: widget.topicId,
              sectionId: widget.sectionId,
              type: widget.type,
              status: widget.status,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * .90,
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: (() {
                switch (widget.status) {
                  case 'To Do':
                    return const Color(0xFFB8CFED);
                  case 'Doing':
                    return const Color(0xFFE4BD3D).withAlpha(80);
                  case 'Done':
                    return const Color(0xFFBAD8B6);
                  case 'Returned':
                    return const Color(0xFFE48A69);
                  case 'Submitted':
                    return const Color(0xFFC6B9F9);
                  case 'Approved':
                    return const Color(0xFF6A9C64);
                  default:
                    return const Color(0xFFDDE4FB);
                }
              })(),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          widget.title,
                          softWrap: true,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          '${widget.section} | ${widget.type}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                const Icon(
                                  Icons.access_time_filled_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 7),
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
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                                            .deleteAssignedTask(
                                                widget.topicId, widget.id);
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
                    const SizedBox(height: 8),
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                        widget.imageurl,
                      ),
                      radius: 20, // Adjust radius as needed
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
