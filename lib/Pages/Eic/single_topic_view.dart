import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nuntium_mobile/Pages/Eic/create_task_page.dart';
import 'package:nuntium_mobile/Pages/Eic/subtaskview.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

class TopicSingleRead extends ConsumerStatefulWidget {
  final String id;
  final String section;
  final String sectionId;

  const TopicSingleRead({
    super.key,
    required this.id,
    required this.section,
    required this.sectionId,
  });

  @override
  ConsumerState<TopicSingleRead> createState() => _TopicSingleReadState();
}

class _TopicSingleReadState extends ConsumerState<TopicSingleRead> {
  final firebaseFunctions = FirebaseFunctions();

  @override
  Widget build(BuildContext context) {
    final topicView = ref.watch(topicDataProvider(widget.id));
    final canUserEdit =
        firebaseFunctions.canUserEdit(firebaseFunctions.auth.currentUser!.uid);

    return Scaffold(
      appBar: const CustomAppBar(
        appbarTitle: 'Tasks',
        hasNavigated: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 40,
        ),
        child: topicView.when(
          data: (topicView) {
            if (topicView.isEmpty) {
              return const Center(
                child: Text('Error: No Topic Found'),
              );
            }

            final deadline = topicView['deadline'] as Timestamp;
            final dateString =
                DateFormat('dd/MM/yyyy hh:mm a').format(deadline.toDate());

            int totalSubtask = topicView['total_subtask'];
            int completedSubtask = topicView['completed_subtask'];

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Task Title: ',
                          style: TextStyle(
                            color: Color(0xFF020B40),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    FutureBuilder<bool>(
                      future: canUserEdit,
                      builder:
                          (BuildContext context, AsyncSnapshot<bool> snapshot) {
                        if (snapshot.hasData) {
                          final userCanEdit =
                              snapshot.data!; // Safely unwrap the bool

                          return userCanEdit
                              ? Align(
                                  alignment: Alignment.topRight,
                                  child: IconButton(
                                    onPressed: () {
                                      print('editing topic na ey');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CreateTaskPage(
                                            topicId: widget.id,
                                            deadline: dateString,
                                            details: topicView['details'],
                                            priority: topicView['priority'],
                                            title: topicView['title'],
                                            isEditing: true,
                                            sectionName: widget.section,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.edit),
                                  ),
                                )
                              : const SizedBox.shrink();
                        } else if (snapshot.hasError) {
                          return Text(
                              'Error: ${snapshot.error}'); // Handle error appropriately
                        } else {
                          return const CircularProgressIndicator(); // Show loading indicator
                        }
                      },
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    topicView['title'],
                    style: const TextStyle(
                      color: Color(0xFF020B40),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ' ${widget.section} | $dateString | $totalSubtask tasks',
                    style: const TextStyle(
                      color: Color(0xFF505050),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ' Created by: ${topicView['userName']} | ${topicView['priority']}',
                    style: const TextStyle(
                      color: Color(0xFF505050),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Details',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    topicView['details'],
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                StepProgressIndicator(
                  totalSteps: 6,
                  currentStep: topicView['projectStep'],
                  selectedColor: const Color(0XFF020B40),
                  unselectedColor: const Color(0XFF0E0E0E).withAlpha(90),
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
                      '$completedSubtask of $totalSubtask Tasks Done!',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const SizedBox(height: 10),
                topicView['status'] != 'pendingAPR'
                    ? SizedBox(
                        height: 60,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: FirebaseAuth.instance.currentUser != null
                              ? () async {
                                  print('tasks viewed');
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    )),
                                    builder: (context) => SubTaskView(
                                      topicId: widget.id,
                                      section: widget.section,
                                      sectionId: widget.sectionId,
                                    ),
                                  );
                                }
                              : () async {
                                  print('di nakalogin pano nangyari yon');

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please login to do this'),
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0XFF020B40),
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Align(
                            alignment: Alignment.center,
                            child: Text(
                              'View the Tasks',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                const SizedBox(height: 10),
                SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: FirebaseAuth.instance.currentUser != null
                        ? () async {
                            print('timeline viewed');
                          }
                        : () async {
                            print('di nakalogin pano nangyari yon');

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please login to comment'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0XFFD4AF37),
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'View the Timeline',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0XFF020B40),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (topicView['status'] == 'pendingPST')
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      'This Topic is PENDING FOR PUBLISHING',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 15,
                      ),
                    ),
                  ),
                if (topicView['status'] == 'pendingAPR')
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      'This Topic is PENDING FOR APPROVAL',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 15,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                if (topicView['status'] == 'pendingAPR')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirm Approval'),
                                content: const Text(
                                    'Are you sure you want to approve this topic?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop(true);

                                      print('topic approved');
                                    },
                                    child: const Text('Approve'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm == true) {
                            try {
                              await firebaseFunctions
                                  .approveToCreate(widget.id);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Topic approved successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Failed to approve this topic: $error'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Approve',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirm Rejection'),
                                content: const Text(
                                    'Are you sure you want to reject this topic?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop(true);

                                      print('topic declined');
                                    },
                                    child: const Text('Reject'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm == true) {
                            try {
                              await firebaseFunctions.rejectToCreate(widget.id);

                              ref.invalidate(topicDataProvider(widget.id));

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Topic rejected successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Failed to reject topic: $error'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Reject',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (topicView['status'] == 'pendingPST')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirm Approval'),
                                content: const Text(
                                    'Are you sure you want to approve this topic?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop(true);
                                      print('topic approved for posting');
                                    },
                                    child: const Text('Approve'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Approve',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirm Rejection'),
                                content: const Text(
                                    'Are you sure you want to reject this topic?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop(true);
                                      print('topic declined');
                                    },
                                    child: const Text('Reject'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Reject',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
          error: (error, stack) => Center(child: Text('Error: $error')),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
