import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:nuntium_mobile/Pages/Eic/create_task_page.dart';
import 'package:nuntium_mobile/Pages/Eic/singletopic_header.dart';
import 'package:nuntium_mobile/Pages/Eic/subtaskview.dart';
import 'package:nuntium_mobile/Pages/Eic/timelinev2.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/image_processor/image_upload_service.dart';
import 'package:nuntium_mobile/models/topic_content_model.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class TopicSingleRead extends ConsumerStatefulWidget {
  final String id;
  final String section;
  final String member1;
  final String member2;
  final int otherMember;
  final String status;

  const TopicSingleRead({
    super.key,
    required this.id,
    required this.section,
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

  Future<void> _refreshData() async {
    ref.invalidate(topicDataProvider);
    ref.invalidate(singleViewTopicContent);
    ref.invalidate(viewAllImageInParent);
  }

  @override
  Widget build(BuildContext context) {
    final topicViewer = ref.watch(topicDataProvider(widget.id));
    final taskContent = ref.watch(singleViewTopicContent(widget.id));
    final allImageView = ref.watch(viewAllImageInParent(widget.id));
    TopicContentModel? latestContent = taskContent.valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0XFFEBEBEB),
      appBar: const CustomAppBar(
        appbarTitle: 'Tasks',
        hasNavigated: false,
      ),
      body: CustomRefreshIndicator(
        onRefresh: _refreshData,
        builder: (
          BuildContext context,
          Widget child,
          IndicatorController controller,
        ) {
          return AnimatedBuilder(
            animation: controller,
            builder: (BuildContext context, _) {
              return Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(
                        top: controller.value *
                            MediaQuery.of(context).size.height *
                            0.1),
                    child: child,
                  ),
                  if (controller.isArmed)
                    const Text(
                      "Release to Refresh",
                      style: TextStyle(
                          color: Color(0XFF020B40),
                          fontWeight: FontWeight.w700,
                          fontSize: 17),
                    ),
                  if (controller.isLoading || controller.isLoading)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0XFF020B40),
                      ), // Change color
                      strokeWidth: 4.0,
                    ),
                ],
              );
            },
          );
        },
        child: Padding(
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
                    final steps = getProgressSteps(topicView);

                    final currentStepIndex = steps.indexWhere(
                        (step) => step.step == topicView['projectStep']);
                    final bool hasNextStep =
                        currentStepIndex + 1 < steps.length;
                    final currentStepLabel =
                        currentStepIndex != -1 && hasNextStep
                            ? steps[currentStepIndex + 1].label
                            : 'Content has been Published';

                    return SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SingleTopicHeader(
                              headerText: 'Topic Information',
                              trailing: FutureBuilder<bool>(
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
                                                            const Color(
                                                                0XFFD23737))
                                                    : Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              CreateTaskPage(
                                                            topicId: widget.id,
                                                            deadline:
                                                                dateString,
                                                            details: topicView[
                                                                'details'],
                                                            title: topicView[
                                                                'title'],
                                                            isEditing: true,
                                                            sectionName:
                                                                widget.section,
                                                          ),
                                                        ),
                                                      );
                                              },
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                              ),
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
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              width: MediaQuery.of(context).size.width * .95,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withAlpha(80),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(2, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
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
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        ' ${widget.section} | $dateString | $totalSubtask tasks',
                                        style: const TextStyle(
                                          color: Color(0xFF505050),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        ' Created by: ${topicView['assignerName']} | Status: ${topicView['status']}',
                                        style: const TextStyle(
                                          color: Color(0xFF505050),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Topic Details',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        topicView['details'],
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  _divider(context),
                                  const SizedBox(height: 15),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
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
                                        child: SizedBox(
                                          height: 50,
                                          child: ElevatedButton(
                                            onPressed: FirebaseAuth
                                                        .instance.currentUser !=
                                                    null
                                                ? () async {
                                                    topicView['status'] ==
                                                                'pendingAPR' ||
                                                            topicView[
                                                                    'status'] ==
                                                                'Rejected'
                                                        ? Fluttertoast.showToast(
                                                            msg:
                                                                "Topic is not approved yet",
                                                            toastLength: Toast
                                                                .LENGTH_LONG,
                                                            backgroundColor:
                                                                const Color(
                                                                    0XFFD23737))
                                                        : showModalBottomSheet(
                                                            context: context,
                                                            isScrollControlled:
                                                                true,
                                                            backgroundColor:
                                                                Colors.white,
                                                            shape:
                                                                const RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .vertical(
                                                              top: Radius
                                                                  .circular(20),
                                                            )),
                                                            builder:
                                                                (context) =>
                                                                    SubTaskView(
                                                              topicId:
                                                                  widget.id,
                                                              section: widget
                                                                  .section,
                                                            ),
                                                          );
                                                  }
                                                : () async {
                                                    print(
                                                        'di nakalogin pano nangyari yon');

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Please login to do this'),
                                                        duration: Duration(
                                                            seconds: 2),
                                                        behavior:
                                                            SnackBarBehavior
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
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
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
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  topicView['section'] != 'Photojournalism'
                                      ? ElevatedButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Content Preview'),
                                                  content:
                                                      _buildPreviewContentDialog(
                                                          taskContent,
                                                          topicView,
                                                          context,
                                                          allImageView),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      child:
                                                          const Text('Close'),
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            side: const BorderSide(
                                              color: Colors.black,
                                              width: 2,
                                            ),
                                            elevation: 10,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Align(
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Content Preview',
                                              style: TextStyle(
                                                color: Color(0XFF020B40),
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        )
                                      : SizedBox(
                                          height: 60,
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              print('image bottomshit viewed');
                                              showAllImages(
                                                context,
                                                allImageView,
                                                topicView['section'] ==
                                                    'Photojournalism',
                                                showImageIsLoading,
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
                                                'View Images',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            const SingleTopicHeader(
                              headerText: 'Progress Report',
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              width: MediaQuery.of(context).size.width * .95,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(10),
                                    bottomRight: Radius.circular(10)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withAlpha(80),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(2, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '${topicView['projectStep']} of ${steps.last.step} steps completed!',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Next Step: $currentStepLabel',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Column(
                                    children: steps.map((step) {
                                      final approved =
                                          topicView['projectStep'] >= step.step;
                                      final reason = step.reasonKey != null &&
                                              topicView
                                                  .containsKey(step.reasonKey)
                                          ? topicView[step.reasonKey]
                                          : null;
                                      return _buildApprovalTile(
                                        context: context,
                                        approved: approved,
                                        label: step.label,
                                        reason: reason,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                  if (latestContent == null) {
                    return const CircularProgressIndicator();
                  }
                  return _conditionalRenderApproval(
                    _canUserEditFuture,
                    topicView,
                    latestContent.pubmatUrls.isNotEmpty,
                  );
                },
                error: (error, stack) => Text('Error: $error'),
                loading: () => const CircularProgressIndicator(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SizedBox _buildPreviewContentDialog(
      AsyncValue<TopicContentModel> taskContent,
      Map<String, dynamic> topicView,
      BuildContext context,
      AsyncValue<List<String>> allImageView) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: SingleChildScrollView(
        child: taskContent.when(
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

            return _articlePreview(viewContent, context, topicView);
          },
          error: (error, stack) => Center(child: Text('Error: $error')),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
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
            ? AspectRatio(
                aspectRatio: 1, // Always square
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
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
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
                            return const Center(
                                child: Text('Failed to load image'));
                          },
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
          textAlign: TextAlign.justify,
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Approve all subtask content!',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 15,
                ),
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
                                      content:
                                          Text('Works approved successfully!'),
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
                                  fontSize: 15,
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
            },
          )
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Timeline',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
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

        // Helper for a colored info message
        Widget infoMsg(String msg, {Color color = Colors.green}) => Align(
              alignment: Alignment.bottomCenter,
              child: Text(msg, style: TextStyle(color: color, fontSize: 15)),
            );

        // Helper for a disabled button
        Widget disabledButton(String label) => ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            );

        // Approval for Publishing (PST)
        if (status == 'pendingPST') {
          if (!hasPubmatImages) {
            return infoMsg('This Topic has no uploaded PUBMATS yet.');
          }
          if (showShowApprovalPST(topicView, userCanEdit)) {
            return Row(
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
                              'Are you sure you want to approve this now?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
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
              ],
            );
          }
          if (showShowPSTRespondent(topicView, userCanEdit)) {
            return infoMsg('You have already responded to this approval',
                color: Colors.red);
          }
          if (topicView['role'] == 'eic' &&
              !topicView.containsKey('eicApprovedPST')) {
            return infoMsg('Waiting for approval of other board members',
                color: Colors.red);
          }
          return infoMsg('This Topic is PENDING FOR PUBLISHING');
        }

        // Approval for Creation (APR) or Rejected
        if ((status == 'pendingAPR' || status == 'Rejected') &&
            !topicView.containsKey('eicApproved')) {
          List<Widget> widgets = [
            infoMsg('This Topic is PENDING FOR APPROVAL', color: Colors.red),
          ];
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
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
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
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
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
            widgets.add(infoMsg('You have already responded to this approval!',
                color: Colors.red));
          } else if (topicView['role'] == 'eic' &&
              !topicView.containsKey('eicApproved') &&
              status == 'pendingAPR') {
            widgets.add(infoMsg('Waiting for approval of other board members',
                color: Colors.red));
          }
          return Column(mainAxisSize: MainAxisSize.min, children: widgets);
        }

        // Rejected by EIC
        if (status == 'Rejected' &&
            topicView.containsKey('eicApproved') &&
            topicView['eicApproved'] == false) {
          return infoMsg('Topic has been rejected by the Editor-In-Chief',
              color: Colors.red);
        }

        // Default: nothing to show
        return const SizedBox.shrink();
      },
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
    required String label,
    required String? reason,
  }) {
    Widget leadingIcon;
    Widget trailingIcon;
    if (reason != null) {
      trailingIcon = IconButton(
        icon: const Icon(Icons.help_outline, color: Colors.grey),
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('$label Rejection Reason'),
              content: reason != null
                  ? Text('Reason: $reason')
                  : const Text('No specific reason provided.'),
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
    } else if (approved == true) {
      leadingIcon = const Icon(Icons.check_circle, color: Colors.green);
      trailingIcon = const SizedBox.shrink();
    } else {
      leadingIcon = const Icon(Icons.help_outline, color: Colors.grey);
      trailingIcon = const SizedBox.shrink();
    }

    return ListTile(
      leading: leadingIcon,
      title: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF505050),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
      trailing: trailingIcon,
    );
  }
}

class ProgressStep {
  final int step;
  final String label;
  final String? reasonKey; // The key in topicView for rejection reason

  ProgressStep(this.step, this.label, {this.reasonKey});
}

// In your build method or a helper function:
List<ProgressStep> getProgressSteps(Map<String, dynamic> topicView) {
  final type = topicView['section']; // Adjust this key to your actual type key

  if (type == 'Photojournalism') {
    return [
      ProgressStep(1, 'Topic Created'),
      ProgressStep(2, 'Associate Editor Approval',
          reasonKey: 'AssociateRejected'),
      ProgressStep(3, 'Managing Editor Approval',
          reasonKey: 'ManagingRejected'),
      ProgressStep(4, 'Editor-in-Chief Approval', reasonKey: 'eicRejected'),
      ProgressStep(5, 'Subtask 1 Created'),
      ProgressStep(6, 'Subtask 2 Created'),
      ProgressStep(7, 'Subtask 3 Created'),
      ProgressStep(8, 'Member 1 Submission'),
      ProgressStep(9, 'Member 2 Submission'),
      ProgressStep(10, 'Member 3 Submission'),
      ProgressStep(11, 'Subtask 1 Approval'),
      ProgressStep(12, 'Subtask 2 Approval'),
      ProgressStep(13, 'Subtask 3 Approval'),
      ProgressStep(14, 'Associate Approval for Posting'),
      ProgressStep(15, 'Managing Approval for Posting'),
      ProgressStep(16, 'EIC Approval for Posting'),
      ProgressStep(17, 'Article Posted'),
    ];
  } else {
    // Default: Writing and Pubmat
    return [
      ProgressStep(1, 'Topic Created'),
      ProgressStep(2, 'Associate Editor Approval',
          reasonKey: 'AssociateRejected'),
      ProgressStep(3, 'Managing Editor Approval',
          reasonKey: 'ManagingRejected'),
      ProgressStep(4, 'Editor-in-Chief Approval', reasonKey: 'eicRejected'),
      ProgressStep(5, 'Pubmat Task Auto Created'),
      ProgressStep(6, 'Writing Task Auto Created'),
      ProgressStep(7, 'Pubmat Task Submitted'),
      ProgressStep(8, 'Writing Task Submitted'),
      ProgressStep(9, 'Pubmat Task Approved'),
      ProgressStep(10, 'Writing Task Approved'),
      ProgressStep(11, 'Associate Approval for Posting'),
      ProgressStep(12, 'Managing Approval for Posting'),
      ProgressStep(13, 'EIC Approval for Posting'),
      ProgressStep(14, 'Posted'),
    ];
  }
}
