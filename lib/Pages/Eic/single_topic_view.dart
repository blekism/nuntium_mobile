import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nuntium_mobile/Pages/Eic/create_task_page.dart';
import 'package:nuntium_mobile/Pages/Eic/subtaskview.dart';
import 'package:nuntium_mobile/Pages/Eic/timelinev2.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/image_processor/image_upload_service.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

class TopicSingleRead extends ConsumerStatefulWidget {
  final String id;
  final String section;
  final String sectionId;
  final String member1;
  final String member2;
  final int otherMember;
  final String status;

  const TopicSingleRead({
    super.key,
    required this.id,
    required this.section,
    required this.sectionId,
    this.member1 = '',
    this.member2 = '',
    this.otherMember = 0,
    required this.status,
  });

  @override
  ConsumerState<TopicSingleRead> createState() => _TopicSingleReadState();
}

class _TopicSingleReadState extends ConsumerState<TopicSingleRead> {
  final firebaseFunctions = FirebaseFunctions();
  bool showImageIsLoading = true;

  Future<void> deleteImage(int index, List<String> retrievedImages) async {
    try {
      await firebaseFunctions.deleteImageInParent(
        index,
        retrievedImages,
        widget.id,
      );

      print('image deleted successfully');
      setState(() {
        retrievedImages.removeAt(index);
      });
    } catch (e) {
      print("Error deleting image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicView = ref.watch(topicDataProvider(widget.id));
    final canUserEdit =
        firebaseFunctions.canUserEdit(firebaseFunctions.auth.currentUser!.uid);
    final taskContent = ref.watch(singleViewTopicContent(widget.id));
    final allImageView = ref.watch(viewAllImageInParent(widget.id));

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
        child: Column(
          children: [
            Expanded(
              child: topicView.when(
                data: (topicView) {
                  if (topicView.isEmpty) {
                    return const Center(
                      child: Text('Error: No Topic Found'),
                    );
                  }

                  final deadline = topicView['deadline'] as Timestamp;
                  final dateString = DateFormat('dd/MM/yyyy hh:mm a')
                      .format(deadline.toDate());

                  int totalSubtask = topicView['total_subtask'];
                  int completedSubtask = topicView['completed_subtask'];

                  return SingleChildScrollView(
                    child: Column(
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
                            widget.status == "pendingPST" ||
                                    widget.status == "Done"
                                ? const SizedBox.shrink()
                                : FutureBuilder<bool>(
                                    future: canUserEdit,
                                    builder: (BuildContext context,
                                        AsyncSnapshot<bool> snapshot) {
                                      if (snapshot.hasData) {
                                        final userCanEdit = snapshot.data!;

                                        return userCanEdit
                                            ? Align(
                                                alignment: Alignment.topRight,
                                                child: IconButton(
                                                  onPressed: () {
                                                    print(
                                                        'editing topic na ey');
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            CreateTaskPage(
                                                          topicId: widget.id,
                                                          deadline: dateString,
                                                          details: topicView[
                                                              'details'],
                                                          priority: topicView[
                                                              'priority'],
                                                          title: topicView[
                                                              'title'],
                                                          isEditing: true,
                                                          sectionName:
                                                              widget.section,
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
                                  ),
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
                          unselectedColor:
                              const Color(0XFF0E0E0E).withAlpha(90),
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
                        const SizedBox(height: 15),
                        topicView['section'] == 'XDEPw2VPYdeFdKQRuRpA'
                            ? SizedBox(
                                height: 60,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    print('image bottomshit viewed');

                                    showAllImages(
                                      context,
                                      allImageView,
                                      showImageIsLoading,
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
                                      'View Images',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : taskContent.when(
                                data: (viewContent) {
                                  if (viewContent.pubmatUrl.isEmpty &&
                                      viewContent.headline.isEmpty &&
                                      viewContent.writtenContent.isEmpty) {
                                    // Data is empty, show alternative UI
                                    return const Center(
                                      child: Text(
                                        'Content Preview will appear here once available',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }

                                  print("image is ${viewContent.pubmatUrl}");
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          viewContent.headline,
                                          softWrap: true,
                                          maxLines: 3,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.network(
                                          viewContent.pubmatUrl,
                                          fit: BoxFit.cover,
                                          alignment: Alignment.center,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              .8,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              .35,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        viewContent.writtenContent,
                                        softWrap: true,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      if (viewContent.pubmatStatus ==
                                              'Submitted' &&
                                          viewContent.writtenStatus ==
                                              'Submitted')
                                        const Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Text(
                                            'Approve all subtask content!',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      if (viewContent.pubmatStatus ==
                                              'Submitted' &&
                                          viewContent.writtenStatus ==
                                              'Submitted')
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () async {
                                                final confirm =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title: const Text(
                                                          'Confirm Approval'),
                                                      content: const Text(
                                                          'Are you sure you want to approve these works?'),
                                                      actions: <Widget>[
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(false),
                                                          child: const Text(
                                                              'Cancel'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () async {
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true);

                                                            print(
                                                                'works approved');
                                                          },
                                                          child: const Text(
                                                              'Approve'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );

                                                if (confirm == true) {
                                                  try {
                                                    await firebaseFunctions
                                                        .massApprove(
                                                      widget.id,
                                                      viewContent.pubmatId,
                                                      viewContent.writingId,
                                                    );

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Works approved successfully!'),
                                                        backgroundColor:
                                                            Colors.green,
                                                      ),
                                                    );
                                                  } catch (error) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'Failed to approve works: $error'),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                elevation: 10,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
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
                                          ],
                                        ),
                                    ],
                                  );
                                },
                                error: (error, stack) =>
                                    Center(child: Text('Error: $error')),
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  );
                },
                error: (error, stack) => Center(child: Text('Error: $error')),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            topicView.when(
              data: (topicView) {
                final deadline = topicView['deadline'] as Timestamp;
                final dateString =
                    DateFormat('dd/MM/yyyy hh:mm a').format(deadline.toDate());
                int totalSubtask = topicView['total_subtask'] as int;

                return Column(
                  children: [
                    topicView['status'] != 'pendingAPR'
                        ? SizedBox(
                            height: 60,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: FirebaseAuth.instance.currentUser !=
                                      null
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

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Please login to do this'),
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
                                print('timeline viewed: ${widget.id}');

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TimelineV2Page(
                                        topicId: widget.id,
                                        title: topicView['title'],
                                        sectionName: widget.section,
                                        deadline: dateString,
                                        totalSubtask: totalSubtask,
                                        member1Url: widget.member1,
                                        member2Url: widget.member2,
                                        otherMembers: widget.otherMember,
                                        projectStep: topicView['projectStep']),
                                  ),
                                );
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
                                      content:
                                          Text('Topic approved successfully!'),
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
                                  await firebaseFunctions
                                      .rejectToCreate(widget.id);

                                  ref.invalidate(topicDataProvider(widget.id));

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Topic rejected successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (error) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Failed to reject topic: $error'),
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
              error: (error, stack) => Text('Error: $error'),
              loading: () => const CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }

  void showAllImages(
    BuildContext context,
    AsyncValue<List<String>> retAllImage,
    bool isLoading,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Checking for similar images..."),
            ],
          ),
        );
      },
    );

    List<String> imagesToShow = [];
    retAllImage.whenData((data) {
      if (data.isEmpty) {
        // If the list is empty, immediately close the dialog and show the bottom sheet
        Navigator.of(context).pop();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (modalContext) {
            return _buildImageGrid(modalContext, const AsyncValue.data([]), {});
          },
        );
      } else {
        imagesToShow = data;
        // Perform the similarity check
        final imageUploadService = ImageUploadService();

        imageUploadService
            .findSimilarExistingImages(imagesToShow)
            .then((similarImagesMap) {
          Navigator.of(context).pop();

          // Show the similarity dialog if similar images are found and the widget is still mounted
          if (similarImagesMap.isNotEmpty && mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Similar Images Found"),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: similarImagesMap.entries.map((entry) {
                        final currentImageUrl = entry.key;
                        final similarUrls = entry.value;

                        print("Image URL: $currentImageUrl");
                        if (similarUrls.isNotEmpty) {
                          for (final url in similarUrls) {
                            print("Similar Image URL: $url");
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Image: ${currentImageUrl.split('/').last.substring(0, 15)}..."),
                              if (similarUrls.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Similar to:"),
                                    ...similarUrls.map((url) => Text(
                                        "- ${url.split('/').last.substring(0, 15)}...")),
                                  ],
                                )
                              else
                                const Text(
                                    "No similar images found for this image."),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text("OK"),
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Now show the bottom modal sheet with the images
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          isDismissible: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (modalContext) {
                            return _buildImageGrid(
                                modalContext, retAllImage, similarImagesMap);
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            );
          } else {
            // If no similar images found, immediately show the bottom modal sheet
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              isDismissible: true,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (modalContext) {
                return _buildImageGrid(
                    modalContext, retAllImage, similarImagesMap);
              },
            );
          }
        });
      }
    });
  }

  Widget _buildImageGrid(
      BuildContext context,
      AsyncValue<List<String>> retImagesView,
      Map<String, List<String>> similarImagesMap) {
    return FractionallySizedBox(
      heightFactor: 0.80,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: retImagesView.when(
                data: (retImages) {
                  if (retImages.isEmpty) {
                    return const Center(child: Text('No images found'));
                  }
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: retImages.length,
                    itemBuilder: (context, index) {
                      final imageUrl = retImages[index];
                      final isSimilar = similarImagesMap.containsKey(imageUrl);
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _openFullScreen(context, index, retImages),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      // Handle delete functionality
                                      await deleteImage(
                                        index,
                                        retImages,
                                      );
                                      print('Photo at index $index deleted');
                                    },
                                  ),
                                ),
                                if (isSimilar)
                                  Positioned(
                                    bottom: 5,
                                    left: 5,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Similar',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                error: (error, stack) => Center(child: Text('Error: $error')),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context, int index, List<String> images) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: PhotoViewGallery.builder(
            itemCount: images.length,
            builder: (context, pageIndex) => PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(images[pageIndex]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            pageController: PageController(initialPage: index),
          ),
        ),
      ),
    );
  }
}
