import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:nuntium_mobile/Pages/Eic/create_task_page.dart';
import 'package:nuntium_mobile/Pages/Eic/subtaskview.dart';
import 'package:nuntium_mobile/Pages/Eic/timelinev2.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/image_processor/image_upload_service.dart';
import 'package:nuntium_mobile/models/topic_content_model.dart';
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
  late Future<bool> _canUserEditFuture;
  final PageController _pageController = PageController(viewportFraction: 0.9);
  bool hasPubmatImages = false;

  Future<void> deleteImage(
    int index,
    List<String> retrievedImages,
    StateSetter setModalState, // Add StateSetter parameter
  ) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this image?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return; // User cancelled
    }

    // Show loading indicator (optional, but good UX)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Call Firebase function to delete from storage and Firestore
      await firebaseFunctions.deleteImageInParent(
        index,
        retrievedImages,
        widget.id,
      );

      print('Image deleted successfully from backend');

      // Update the local list AND trigger rebuild of the modal sheet
      setModalState(() {
        retrievedImages.removeAt(index);
      });

      // Invalidate the provider to ensure the main page also gets updated data next time
      ref.invalidate(viewAllImageInParent);

      if (mounted) {
        Navigator.of(context).pop(); // Pop loading indicator
      }
    } catch (e) {
      print("Error deleting image: $e");
      if (mounted) {
        Navigator.of(context).pop(); // Pop loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting image: $e")),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _canUserEditFuture =
        firebaseFunctions.canUserEdit(firebaseFunctions.auth.currentUser!.uid);
  }

  bool showShowApprovalAPR(Map<String, dynamic> topicView, bool userCanEdit) {
    final role = topicView['role'];

    switch (role) {
      case 'eic':
        //ibig sabihin nung contains key here is sinsabi na
        //may response na yung tatlo kaya pwede na magrespond si eic
        return topicView.containsKey('ManagingApproved') &&
            topicView.containsKey('AssociateApproved') &&
            !topicView.containsKey('eicApproved');
      case 'Managing':
        return !topicView.containsKey('ManagingApproved');
      case 'Associate':
        return !topicView.containsKey('AssociateApproved');
      default:
        return false;
    }
  }

  bool showShowAPRRespondent(Map<String, dynamic> topicView, bool userCanEdit) {
    final role = topicView['role'];

    switch (role) {
      case 'eic':
        //ibig sabihin nung contains key here is sinsabi na
        //may response na yung tatlo kaya pwede na magrespond si eic
        return topicView.containsKey('eicApproved');
      case 'Managing':
        return topicView.containsKey('ManagingApproved');
      case 'Associate':
        return topicView.containsKey('AssociateApproved');
      default:
        return false;
    }
  }

  bool showShowApprovalPST(Map<String, dynamic> topicView, bool userCanEdit) {
    final role = topicView['role'];

    switch (role) {
      case 'eic':
        //ibig sabihin nung contains key here is sinsabi na
        //may response na yung tatlo kaya pwede na magrespond si eic
        return topicView.containsKey('ManagingApprovedPST') &&
            topicView.containsKey('AssociateApprovedPST') &&
            !topicView.containsKey('eicApprovedPST');
      case 'Managing':
        return !topicView.containsKey('ManagingApprovedPST');
      case 'Associate':
        return !topicView.containsKey('AssociateApprovedPST');
      default:
        return false;
    }
  }

  bool showShowPSTRespondent(Map<String, dynamic> topicView, bool userCanEdit) {
    final role = topicView['role'];

    switch (role) {
      case 'eic':
        //ibig sabihin nung contains key here is sinsabi na
        //may response na yung tatlo kaya pwede na magrespond si eic
        return topicView.containsKey('eicApprovedPST');
      case 'Managing':
        return topicView.containsKey('ManagingApprovedPST');
      case 'Associate':
        return topicView.containsKey('AssociateApprovedPST');
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicViewer = ref.watch(topicDataProvider(widget.id));
    final taskContent = ref.watch(singleViewTopicContent(widget.id));
    final allImageView = ref.watch(viewAllImageInParent(widget.id));

    return Scaffold(
      appBar: const CustomAppBar(
        appbarTitle: 'Tasks',
        hasNavigated: false,
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 15,
          right: 15,
          bottom: 10,
          top: 10,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: topicViewer.when(
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
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FutureBuilder<bool>(
                          future: _canUserEditFuture,
                          builder: (BuildContext context,
                              AsyncSnapshot<bool> snapshot) {
                            if (snapshot.hasData) {
                              final userCanEdit = snapshot.data!;

                              return userCanEdit
                                  ? Align(
                                      alignment: Alignment.topRight,
                                      child: IconButton(
                                        onPressed: () {
                                          print('editing topic na ey');
                                          widget.status == "pendingPST" ||
                                                  widget.status == "Done"
                                              ? Fluttertoast.showToast(
                                                  msg:
                                                      "Details of ongoing tasks are no longer editable",
                                                  toastLength:
                                                      Toast.LENGTH_SHORT,
                                                  backgroundColor:
                                                      const Color(0XFFD23737))
                                              : Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        CreateTaskPage(
                                                      topicId: widget.id,
                                                      deadline: dateString,
                                                      details:
                                                          topicView['details'],
                                                      title: topicView['title'],
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
                            ' Created by: ${topicView['userName']} | Status: ${topicView['status']}',
                            style: const TextStyle(
                              color: Color(0xFF505050),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
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
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Approval Status'),
                                      content: _buildApprovalDialogContent(
                                          topicView), // Use the helper function
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text('Close'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0XFFD4AF37),
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Approval Status',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${topicView['projectStep']} of 6 Project Steps done!',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          spacing: 15,
                          children: [
                            Expanded(
                              child: _timelineButton(
                                context,
                                topicView,
                                dateString,
                                totalSubtask,
                              ),
                            ),
                            Expanded(
                              child: topicView['status'] == 'pendingAPR' ||
                                      topicView['status'] == 'Rejected'
                                  ? SizedBox(
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          print('tasks viewed');
                                          Fluttertoast.showToast(
                                              msg: "Topic is not approved yet",
                                              toastLength: Toast.LENGTH_LONG,
                                              backgroundColor:
                                                  const Color(0XFFD23737));
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(
                                              153, 2, 11, 64),
                                          elevation: 10,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: const Align(
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Tasks',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: FirebaseAuth
                                                    .instance.currentUser !=
                                                null
                                            ? () async {
                                                print('tasks viewed');
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  backgroundColor: Colors.white,
                                                  shape:
                                                      const RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .vertical(
                                                    top: Radius.circular(20),
                                                  )),
                                                  builder: (context) =>
                                                      SubTaskView(
                                                    topicId: widget.id,
                                                    section: widget.section,
                                                    sectionId: widget.sectionId,
                                                    member1: widget.member1,
                                                    member2: widget.member2,
                                                  ),
                                                );
                                              }
                                            : () async {
                                                print(
                                                    'di nakalogin pano nangyari yon');

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Please login to do this'),
                                                    duration:
                                                        Duration(seconds: 2),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0XFF020B40),
                                          elevation: 10,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: const Align(
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Tasks',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _divider(context),
                        const SizedBox(height: 15),
                        taskContent.when(
                          data: (viewContent) {
                            if (viewContent.pubmatUrls.isEmpty &&
                                viewContent.headline.isEmpty &&
                                viewContent.writtenContent.isEmpty) {
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

                            if (viewContent.pubmatUrls.isNotEmpty) {
                              setState(() {
                                hasPubmatImages = true;
                              });
                            }

                            if (topicView['section'] ==
                                'XDEPw2VPYdeFdKQRuRpA') {
                              return SizedBox(
                                height: 60,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    print('image bottomshit viewed');
                                    showAllImages(
                                      context,
                                      allImageView,
                                      topicView['section'] ==
                                          'XDEPw2VPYdeFdKQRuRpA',
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
                              );
                            } else {
                              return _articlePreview(
                                  viewContent, context, topicView);
                            }
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
            topicViewer.when(
              data: (topicView) {
                return _conditionalRenderApproval(
                    _canUserEditFuture, topicView, hasPubmatImages);
              },
              error: (error, stack) => Text('Error: $error'),
              loading: () => const CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }

  Column _articlePreview(TopicContentModel viewContent, BuildContext context,
      Map<String, dynamic> topicView) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
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
        viewContent.pubmatUrls.isNotEmpty
            ? SizedBox(
                height: MediaQuery.of(context).size.height * .35,
                child: PageView.builder(
                  itemCount: viewContent.pubmatUrls.length,
                  controller: _pageController,
                  itemBuilder: (context, index) {
                    final item = viewContent.pubmatUrls;

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          item.elementAt(index),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Text('Failed to load image');
                          },
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          width: MediaQuery.of(context).size.width * .8,
                          height: MediaQuery.of(context).size.height * .35,
                        ),
                      ),
                    );
                  },
                ),
              )
            : const Text(
                'No uploaded pubmat yet',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
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
        if (topicView['status'] == 'pendingPST')
          TextButton(
            onPressed: () async {
              Fluttertoast.showToast(
                  msg: "Return a task for revision in the individual tasks",
                  toastLength: Toast.LENGTH_LONG,
                  backgroundColor: const Color(0XFFD23737));
            },
            child: const Align(
              alignment: Alignment.center,
              child: Text(
                'Still Needs Revision?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        if (viewContent.pubmatStatus == 'Submitted' &&
            viewContent.writtenStatus == 'Submitted')
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
        if (viewContent.pubmatStatus == 'Submitted' &&
            viewContent.writtenStatus == 'Submitted')
          FutureBuilder<bool>(
              future: _canUserEditFuture,
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                if (snapshot.hasData) {
                  final userCanEdit = snapshot.data!;

                  return userCanEdit
                      ? Row(
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
                                          'Are you sure you want to approve these works?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop(true);

                                            print('works approved');
                                          },
                                          child: const Text('Approve'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirm == true) {
                                  try {
                                    await firebaseFunctions.massApprove(
                                      widget.id,
                                      viewContent.pubmatId,
                                      viewContent.writingId,
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Works approved successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (error) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to approve works: $error'),
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
                                  'Approve Topic Contents',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return const CircularProgressIndicator();
                }
              })
      ],
    );
  }

  Container _divider(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: MediaQuery.of(context).size.width * .85,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  SizedBox _timelineButton(BuildContext context, Map<String, dynamic> topicView,
      String dateString, int totalSubtask) {
    return SizedBox(
      height: 50,
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
                        projectStep: topicView['projectStep']),
                  ),
                );
              }
            : () async {
                print('di nakalogin pano nangyari yon');

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please login to view this'),
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
            'Timeline',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  FutureBuilder<bool> _conditionalRenderApproval(
    Future<bool> canUserEdit,
    Map<String, dynamic> topicView,
    bool hasPubmatImages,
  ) {
    return FutureBuilder<bool>(
      future: canUserEdit,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final bool userCanEdit = snapshot.data ?? false;
        final String status = topicView['status'] ?? '';

        List<Widget> widgets = [];

        if (status == 'pendingPST' && hasPubmatImages) {
          widgets.add(
            const Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                'This Topic is PENDING FOR PUBLISHING',
                style: TextStyle(color: Colors.green, fontSize: 15),
              ),
            ),
          );
        } else if (status == 'pendingPST' && !hasPubmatImages) {
          widgets.add(
            const Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                'This Topic has no uploaded PUBMATS yet.',
                style: TextStyle(color: Colors.green, fontSize: 15),
              ),
            ),
          );
        }

        if (showShowApprovalPST(topicView, userCanEdit) &&
            status == 'pendingPST') {
          widgets.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: hasPubmatImages
                      ? () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirm Approval'),
                                content: const Text(
                                    'Are you sure you want to approve this now?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                    child: const Text('Approve'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm == true) {
                            try {
                              await firebaseFunctions.updateToPost(widget.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Topic approved successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      : () async {
                          Fluttertoast.showToast(
                              msg:
                                  "Topic has no pubmat yet. cannot approve for publishing",
                              toastLength: Toast.LENGTH_SHORT,
                              backgroundColor: const Color(0XFFD23737));
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasPubmatImages
                        ? Colors.green
                        : const Color.fromARGB(87, 76, 175, 79),
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
              ],
            ),
          );
        } else if (showShowPSTRespondent(topicView, userCanEdit) &&
            status == 'pendingPST') {
          widgets.add(
            Align(
              alignment: Alignment.bottomCenter,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'You have already responded to this approval',
                  style: TextStyle(color: Colors.red, fontSize: 15),
                ),
              ),
            ),
          );
        } else if (topicView['role'] == 'eic' &&
            !topicView.containsKey('eicApprovedPST') &&
            status == 'pendingPST') {
          widgets.add(
            Align(
              alignment: Alignment.bottomCenter,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Waiting for approval of other board members',
                  style: TextStyle(color: Colors.red, fontSize: 15),
                ),
              ),
            ),
          );
        }

        if (status == 'pendingAPR' || status == 'Rejected') {
          widgets.add(
            const Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                'This Topic is PENDING FOR APPROVAL',
                style: TextStyle(color: Colors.red, fontSize: 15),
              ),
            ),
          );

          if (showShowApprovalAPR(topicView, userCanEdit) &&
                  status == 'pendingAPR' ||
              status == 'Rejected') {
            widgets.add(
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                                child: const Text('Approve'),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm == true) {
                        try {
                          await firebaseFunctions.approveToCreate(widget.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Topic approved successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
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
                      final TextEditingController rejectionReasonController =
                          TextEditingController();

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Rejection'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                    'Are you sure you want to reject this topic?'),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: rejectionReasonController,
                                  decoration: const InputDecoration(
                                    labelText: 'Reason for rejection',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                ),
                              ],
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                                child: const Text('Reject'),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm == true) {
                        try {
                          final rejectionReason =
                              rejectionReasonController.text;

                          // Pass the rejection reason to the database
                          await firebaseFunctions.rejectToCreate(
                            widget.id,
                            rejectionReason,
                            topicView['role'],
                          );

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
                              content: Text('Failed to reject topic: $error'),
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
            );
          } else if (showShowAPRRespondent(topicView, userCanEdit) &&
                  status == 'pendingAPR' ||
              status == 'Rejected') {
            widgets.add(
              const Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  'You have already responded to this approval!',
                  style: TextStyle(color: Colors.red, fontSize: 15),
                ),
              ),
            );
          } else if (topicView['role'] == 'eic' &&
              !topicView.containsKey('eicApproved') &&
              status == 'pendingAPR') {
            widgets.add(
              Align(
                alignment: Alignment.bottomCenter,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Waiting for approval of other board members',
                    style: TextStyle(color: Colors.red, fontSize: 15),
                  ),
                ),
              ),
            );
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: widgets,
        );
      },
    );
  }

  Widget _buildApprovalDialogContent(Map<String, dynamic> topicView) {
    final String status = topicView['status'] ?? '';
    List<_ApprovalRoleConfig> approvalConfigs = [];

    switch (status) {
      case 'pendingAPR':
      case 'To Do':
      case 'Doing':
        approvalConfigs = [
          _ApprovalRoleConfig(
              approvedKey: 'eicApproved',
              roleName: 'Editor-In-Chief',
              rejectionReasonKey: 'eicRejected'),
          _ApprovalRoleConfig(
              approvedKey: 'AssociateApproved',
              roleName: 'Associate Editor',
              rejectionReasonKey: 'AssociateRejected'),
          _ApprovalRoleConfig(
              approvedKey: 'ManagingApproved',
              roleName: 'Managing Editor',
              rejectionReasonKey: 'ManagingRejected'),
        ];
        break;
      case 'pendingPST':
      case 'Done':
        approvalConfigs = [
          _ApprovalRoleConfig(
              approvedKey: 'eicApprovedPST',
              roleName: 'Editor-In-Chief for Posting',
              rejectionReasonKey: 'eicRejected'),
          _ApprovalRoleConfig(
              approvedKey: 'AssociateApprovedPST',
              roleName: 'Associate Editor for Posting',
              rejectionReasonKey: 'AssociateRejected'),
          _ApprovalRoleConfig(
              approvedKey: 'ManagingApprovedPST',
              roleName: 'Managing Editor for Posting',
              rejectionReasonKey: 'ManagingRejected'),
        ];
        break;
      default:
        // For any other status, approvalConfigs will be empty.
        break;
    }

    if (approvalConfigs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min, // Important for AlertDialog content
      crossAxisAlignment: CrossAxisAlignment.start,
      children: approvalConfigs.map((config) {
        return _buildApprovalTile(
          context: context,
          approved: topicView[config.approvedKey],
          role: config.roleName,
          reason: topicView.containsKey(config.rejectionReasonKey)
              ? topicView[config.rejectionReasonKey]
              : null,
        );
      }).toList(),
    );
  }

  void showAllImages(
    BuildContext context,
    AsyncValue<List<String>> retAllImage,
    bool isPhotography,
    bool isLoading,
  ) async {
    // Get the image URLs first
    List<String> imagesToShow = retAllImage.asData?.value ?? [];

    // --- Conditional Similarity Check ---
    if (isPhotography) {
      // Only show loading and check similarity for Photography
      if (imagesToShow.isEmpty) {
        // If no images, just show the empty grid directly
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (modalContext) {
            // Pass empty data and empty map
            return _buildImageGrid(
                modalContext, const AsyncValue.data([]), {}, isPhotography);
          },
        );
        return; // Exit early
      }

      // Show loading dialog for similarity check
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

      // Perform the similarity check
      final imageUploadService = ImageUploadService();
      try {
        // Add try-finally to ensure dialog is popped
        final similarImagesMap =
            await imageUploadService.findSimilarExistingImages(imagesToShow);

        if (mounted) {
          // Check if widget is still mounted before popping dialog
          Navigator.of(context).pop(); // Pop the loading dialog
        } else {
          return; // Don't proceed if widget is unmounted
        }

        // Show the similarity dialog if similar images are found
        if (similarImagesMap.isNotEmpty && mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              final bool hasSimilarImages =
                  similarImagesMap.values.any((urls) => urls.isNotEmpty);

              return AlertDialog(
                title: const Text("Similar Images Found"),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasSimilarImages
                            ? "Similar images were found!"
                            : "No similar images found for this image.",
                      ),
                      const SizedBox(height: 16),
                      ...similarImagesMap.entries.map((entry) {
                        // You can show other UI here if needed per entry
                        return const SizedBox(); // Placeholder
                      }).toList(),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text("OK"),
                    onPressed: () {
                      if (mounted) {
                        Navigator.of(context).pop(); // Close dialog
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
                              modalContext,
                              retAllImage,
                              similarImagesMap,
                              isPhotography,
                            );
                          },
                        );
                      }
                    },
                  ),
                ],
              );
            },
          );
        } else if (mounted) {
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
              // Pass the empty map as no similar images were found
              return _buildImageGrid(
                  modalContext, retAllImage, {}, isPhotography);
            },
          );
        }
      } catch (e) {
        print("Error during similarity check: $e");
        if (mounted) {
          Navigator.of(context)
              .pop(); // Ensure loading dialog is popped on error
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error checking similarity: $e")));
          // Optionally show the grid anyway, or handle error differently
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            isDismissible: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (modalContext) {
              // Pass empty map on error
              return _buildImageGrid(
                  modalContext, retAllImage, {}, isPhotography);
            },
          );
        }
      }
    } else {
      // --- If type is NOT Photography ---
      // Directly show the bottom sheet without similarity check
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (modalContext) {
          // Pass the retrieved images and an empty map for similar images
          return _buildImageGrid(modalContext, retAllImage, {}, isPhotography);
        },
      );
    }
  }

  Widget _buildImageGrid(
      BuildContext modalContext, // Use the modal's context
      AsyncValue<List<String>> retImagesView,
      Map<String, List<String>> similarImagesMap,
      bool isPhotography) {
    return FractionallySizedBox(
      heightFactor: 0.80,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        // Use StatefulBuilder to get a specific setState for the modal content
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
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
                      // This list will be modified by deleteImage
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
                          final isSimilar =
                              similarImagesMap.containsKey(imageUrl);
                          return Stack(
                            children: [
                              GestureDetector(
                                onTap: () => _openFullScreen(modalContext,
                                    index, retImages), // Use modalContext
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    // Add error and loading builders for robustness
                                    loadingBuilder: (context, child, progress) {
                                      return progress == null
                                          ? child
                                          : const Center(
                                              child:
                                                  CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                          child: Icon(Icons.error,
                                              color: Colors.red));
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: Container(
                                  // Simplified the Stack for the button
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  // Removed inner Stack, padding adjusted on IconButton directly
                                  child: IconButton(
                                    padding: EdgeInsets
                                        .zero, // Adjust padding if needed
                                    constraints:
                                        const BoxConstraints(), // Remove default constraints
                                    icon: const Icon(
                                      Icons.delete_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      // Pass the setModalState to deleteImage
                                      await deleteImage(
                                        index,
                                        retImages, // Pass the current list
                                        setModalState, // Pass the modal's setState
                                      );
                                      print(
                                          'Delete button pressed for index $index');
                                      // No need to print 'deleted' here, deleteImage handles it
                                    },
                                  ),
                                ),
                              ),
                              if (isSimilar && isPhotography)
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
                          );
                        },
                      );
                    },
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
            );
          },
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

  Widget _buildApprovalTile({
    required BuildContext context,
    required bool? approved,
    required String role,
    required String? reason,
  }) {
    Widget leadingIcon;
    Widget trailingIcon;
    if (approved == true) {
      leadingIcon = const Icon(Icons.check_circle, color: Colors.green);
      trailingIcon = const SizedBox.shrink();
    } else if (approved == false) {
      trailingIcon = IconButton(
        icon: const Icon(Icons.help_outline, color: Colors.grey),
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('$role Rejection Reason'),
              content: reason != null
                  ? Text('Reason: $reason')
                  : Text('No specific reason provided.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
          // When dialog closes, user naturally goes back to the first one
        },
      );

      leadingIcon = const Icon(Icons.cancel, color: Colors.red);
    } else {
      leadingIcon = const Icon(Icons.help_outline, color: Colors.grey);
      trailingIcon = const SizedBox.shrink();
    }

    return ListTile(
      leading: leadingIcon,
      title: Text(
        '$role Approved',
        style: const TextStyle(
          color: Color(0xFF505050),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: trailingIcon,
    );
  }
}

class _ApprovalRoleConfig {
  final String approvedKey;
  final String roleName;
  final String rejectionReasonKey;

  _ApprovalRoleConfig({
    required this.approvedKey,
    required this.roleName,
    required this.rejectionReasonKey,
  });
}
