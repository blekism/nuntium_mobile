import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/Eic/assign_task_page.dart';
import 'package:nuntium_mobile/Pages/Eic/fullscreentextfield.dart';
import 'package:nuntium_mobile/Pages/Eic/timelinev2.dart';
import 'package:nuntium_mobile/Pages/LoginRegister/loadingpage.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/image_processor/image_upload_service.dart';
import 'package:nuntium_mobile/models/viewed_task.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker_view/multi_image_picker_view.dart';

class DoAssignedTaskPage extends ConsumerStatefulWidget {
  final String topicId, taskId, section, type, status;

  const DoAssignedTaskPage({
    super.key,
    required this.topicId,
    required this.taskId,
    required this.section,
    required this.type,
    required this.status,
  });

  @override
  ConsumerState<DoAssignedTaskPage> createState() => _DoAssignedTaskPageState();
}

class _DoAssignedTaskPageState extends ConsumerState<DoAssignedTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _headlineController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final firebaseFunctions = FirebaseFunctions();
  final ValueNotifier<String> _contentNotifier = ValueNotifier<String>('');
  bool showImageIsLoading = true;
  final ImageUploadService imageUploadService = ImageUploadService();
  late Future<bool> _canUserEditFuture;
  final TextEditingController _commentController = TextEditingController();
  bool isContentSubmitted = false;
  bool wasSubmitPressed = false;

  @override
  void initState() {
    super.initState();
    _contentController.text = _contentNotifier.value; // Set initial value
    _canUserEditFuture =
        firebaseFunctions.canUserEdit(firebaseFunctions.auth.currentUser!.uid);

    _contentNotifier.addListener(() {
      // Update the controller when the notifier changes
      if (_contentController.text != _contentNotifier.value) {
        _contentController.text = _contentNotifier.value;
        // Move cursor to the end
        _contentController.selection =
            TextSelection.collapsed(offset: _contentController.text.length);
      }
    });
  }

  @override
  void dispose() {
    _contentNotifier
        .dispose(); // Dispose of the ValueNotifier when the widget is disposed
    _headlineController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  final controller = MultiImagePickerController(
    maxImages: 200,
    picker: (allowMultiple) async {
      final pickedFiles = await ImagePicker().pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 100,
      );

      if (pickedFiles.isNotEmpty) {
        return pickedFiles.map((file) {
          return ImageFile(
            file.path, // Add the missing positional argument
            name: file.name, // Extract filename
            path: file.path,
            extension: file.path.split('.').last, // Extract file extension
          );
        }).toList();
      }

      return [];
    },
  );

  Future<void> _uploadImages(
    StateSetter setModalState,
    Map<String, double> uploadProgress,
    List<String> uploadingImagePaths,
  ) async {
    List<String> imageUrls = [];
    List<File> filesToUpload = [];
    final List<ImageFile> imageList = controller.images.toList();

    for (final fileWrapper in controller.images) {
      if (fileWrapper.hasPath) {
        filesToUpload.add(File(fileWrapper.path!));
        uploadingImagePaths
            .add(fileWrapper.path!); // Keep track of uploading paths
      }
    }

    if (filesToUpload.isEmpty) {
      print("No images selected for upload.");
      return;
    }

    final String? userId = firebaseFunctions.auth.currentUser?.uid;
    if (userId == null) {
      print("User not logged in.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in.")),
      );
      return;
    }
    final imageUploadService = ImageUploadService();

    // Call your uploadApprovedImages service method
    final uploadResults = await imageUploadService.uploadApprovedImages(
      approvedImages: filesToUpload,
      userId: userId,
      onProgress: (index, progress) {
        final filePath = imageList[index].path!;
        setModalState(() {
          uploadProgress[filePath] = progress;
        });
        print("Upload Progress for $filePath: $progress");
      },
    );

    // Process the upload results to get the image URLs
    for (final result in uploadResults) {
      if (result.isSuccess && result.url != null) {
        imageUrls.add(result.url!);
      } else if (result.error != null) {
        print("Error uploading ${result.file.path}: ${result.error}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Failed to upload ${result.file.path}: ${result.error}")),
        );
        uploadingImagePaths.remove(result.file.path); // Remove failed upload
        setModalState(() {}); // Update UI
      } else {
        uploadingImagePaths.remove(result.file.path); // Remove if not success
        setModalState(() {}); // Update UI
      }
    }

    print("Image URLs from uploadApprovedImages: $imageUrls");

    // After successfully getting the image URLs from your service,
    // you can then call your Firebase Function with these URLs.
    if (imageUrls.isNotEmpty) {
      await firebaseFunctions.uploadMultiImage(
          widget.topicId, widget.taskId, imageUrls);
      print("Images uploaded successfully via Firebase Function!");
    } else {
      print("No image URLs to pass to Firebase Function.");
    }
  }

  Future<void> _uploadMultiPubmat(
    StateSetter setModalState,
    Map<String, double> uploadProgress,
    List<String> uploadingImagePaths,
  ) async {
    List<String> imageUrls = [];

    for (final fileWrapper in controller.images) {
      if (fileWrapper.hasPath) {
        File file = File(fileWrapper.path!);

        String fileExtension = file.path.split('.').last;
        String fileName =
            "${DateTime.now().millisecondsSinceEpoch}.$fileExtension";

        Reference storageRef =
            FirebaseStorage.instance.ref().child('images/$fileName');

        UploadTask uploadTask = storageRef.putFile(file);

        // Add the image path to the list of uploading images
        uploadingImagePaths.add(fileWrapper.path!);

        try {
          // 1. Listen for upload progress (Stream)
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            double progress = snapshot.bytesTransferred.toDouble() /
                snapshot.totalBytes.toDouble();

            // Update the progress in the map
            setModalState(() {
              uploadProgress[fileWrapper.path!] = progress;
            });

            // Update the UI using setModalState
            setModalState(() {});

            print("Upload Progress: $progress");
            // Update your UI with the progress (e.g., a progress bar)
          }, onError: (error) {
            print("Error listening to snapshot events: $error");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error monitoring upload: $error")),
            );
            // Remove the image path from the list of uploading images in case of error
            uploadingImagePaths.remove(fileWrapper.path!);
            setModalState(() {}); // Update UI to remove progress indicator
          }, onDone: () {
            // Remove the image path from the list of uploading images when done
            uploadingImagePaths.remove(fileWrapper.path!);
            setModalState(() {}); // Update UI to remove progress indicator
          });

          // 2. Await the upload to complete (Future)
          TaskSnapshot snapshot =
              await uploadTask; // Or await uploadTask.whenComplete;

          // 3. Get the download URL (after upload is complete)
          String downloadURL = await snapshot.ref.getDownloadURL();
          imageUrls.add(downloadURL);
        } catch (e) {
          print("Error uploading image: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Image upload failed: $e")),
          );
          // Remove the image path from the list of uploading images in case of error
          uploadingImagePaths.remove(fileWrapper.path!);
          setModalState(() {}); // Update UI to remove progress indicator
          return; // Or continue; if you want to try other images
        }
      }
    }

    print("Image URLs: $imageUrls");

    await firebaseFunctions.pubmatMultiUpload(
      widget.topicId,
      widget.taskId,
      imageUrls,
    );
    print("Images uploaded successfully!");
  }

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

      widget.type == 'Pubmat'
          ? await firebaseFunctions.deleteImageForPubmat(
              index,
              retrievedImages,
              widget.topicId,
              widget.taskId,
            )
          : await firebaseFunctions.deleteImages(
              index,
              retrievedImages,
              widget.topicId,
              widget.taskId,
            );
      ref.invalidate(singleViewTopicContent);

      print('Image deleted successfully from backend');

      // Update the local list AND trigger rebuild of the modal sheet
      setModalState(() {
        retrievedImages.removeAt(index);
      });

      // Invalidate the provider to ensure the main page also gets updated data next time
      ref.invalidate(retImagesProvider((widget.topicId, widget.taskId)));

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
  Widget build(BuildContext context) {
    final assignedTaskView =
        ref.watch(taskWrittenProvider((widget.topicId, widget.taskId)));
    final retImagesView =
        ref.watch(retImagesProvider((widget.topicId, widget.taskId)));

    final allImageView = ref.watch(viewAllImageInParent(widget.topicId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        // If didPop is true, it means the pop happened for other reasons
        if (didPop) {
          return; // Pop already happened, do nothing.
        }

        bool isPotentiallyEditable = widget.status != "Submitted" &&
            widget.status != "Approved" &&
            widget.status != "Done";

        // Determine if the user should be prompted:
        // Prompt ONLY IF the task is potentially editable AND the submit button was NOT just pressed.
        bool shouldPrompt = isPotentiallyEditable && !wasSubmitPressed;

        if (shouldPrompt) {
          final bool shouldDiscard = await _showDiscardConfirmationDialog();
          if (shouldDiscard && mounted) {
            // If the user confirmed discard, manually pop the route.
            // We don't need to pass a specific result back here, but could if needed.
            Navigator.of(context).pop();
          }
          // If shouldDiscard is false, do nothing, stay on the page.
        } else {
          // If no prompt is needed, allow the pop by manually popping.
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: const CustomAppBar(
          appbarTitle: 'Create Your Content',
          hasNavigated: false,
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        assignedTaskView.when(
                          data: (assignedTask) {
                            if (_headlineController.text.isEmpty) {
                              _headlineController.text = assignedTask.headline;
                            }
                            if (_contentNotifier.value.isEmpty) {
                              _contentNotifier.value = assignedTask.content;
                            }
                            if (_contentController.text.isEmpty) {
                              _contentController.text = assignedTask.content;
                            }

                            if (_commentController.text.isEmpty) {
                              _commentController.text = assignedTask.comments;
                            }

                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                    assignedTask.status == "Approved" ||
                                            assignedTask.status == "Done"
                                        ? const SizedBox.shrink()
                                        : FutureBuilder<bool>(
                                            future: _canUserEditFuture,
                                            builder: (BuildContext context,
                                                AsyncSnapshot<bool> snapshot) {
                                              if (snapshot.hasData) {
                                                final userCanEdit = snapshot
                                                    .data!; // Safely unwrap the bool

                                                return userCanEdit
                                                    ? Align(
                                                        alignment:
                                                            Alignment.topRight,
                                                        child: IconButton(
                                                          onPressed: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        AssignTaskPage(
                                                                  isEditing:
                                                                      true,
                                                                  deadline:
                                                                      assignedTask
                                                                          .deadline,
                                                                  member: assignedTask
                                                                      .assignee,
                                                                  taskname:
                                                                      assignedTask
                                                                          .title,
                                                                  tasktype:
                                                                      assignedTask
                                                                          .tasktype,
                                                                  section:
                                                                      assignedTask
                                                                          .assigneeSec,
                                                                  topicId: widget
                                                                      .topicId,
                                                                  taskId:
                                                                      assignedTask
                                                                          .taskId,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          icon: const Icon(
                                                              Icons.edit),
                                                        ),
                                                      )
                                                    : const SizedBox.shrink();
                                              } else if (snapshot.hasError) {
                                                return Text(
                                                    'Error: ${snapshot.error}');
                                              } else {
                                                return const CircularProgressIndicator();
                                              }
                                            },
                                          ),
                                  ],
                                ),
                                const SizedBox(height: 7),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    assignedTask.title,
                                    style: const TextStyle(
                                      color: Color(0xFF020B40),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    ' ${widget.section} | ${assignedTask.deadline} ',
                                    style: const TextStyle(
                                      color: Color(0xFF505050),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    ' Created by: ${assignedTask.assigner}',
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
                                    'Task Details: ',
                                    style: TextStyle(
                                      color: Color(0xFF020B40),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    assignedTask.details,
                                    style: const TextStyle(
                                      color: Color(0xFF020B40),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Assigned To: ${assignedTask.assigneeName}',
                                        style: const TextStyle(
                                          color: Color(0xFF020B40),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    _timelineButton(context, assignedTask),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                assignedTask.hasStarted
                                    ? Column(
                                        children: [
                                          switch (widget.type) {
                                            'Writing' => _headlineLabel(),
                                            _ => const SizedBox.shrink()
                                          },
                                          assignedTask.canCaption
                                              ? _captionLabel()
                                              : const SizedBox.shrink(),
                                          const SizedBox(height: 7),
                                          switch (widget.type) {
                                            'Writing' => _headlineInput(),
                                            _ => const SizedBox.shrink()
                                          },
                                          assignedTask.canCaption
                                              ? _captionInput()
                                              : const SizedBox.shrink(),
                                          const SizedBox(height: 8),
                                          const Align(
                                            alignment: Alignment.topLeft,
                                            child: Text(
                                              'Content',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 7),
                                          switch (widget.type) {
                                            'Writing' => _writingInput(),
                                            'Photography' => _buildImageInput(
                                                context,
                                                allImageView,
                                              ),
                                            'Pubmat' => _buildImageInput(
                                                context,
                                                retImagesView,
                                              ),
                                            _ => const SizedBox.shrink(),
                                          },
                                          const SizedBox(height: 10),
                                          Align(
                                            alignment: Alignment.topLeft,
                                            child: Text(
                                              '${widget.section} Editor Comments',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          _commentContainer(),
                                          const SizedBox(height: 15),
                                          assignedTask.canCaption ||
                                                  widget.type == 'Writing'
                                              ? _bottomButtons(
                                                  assignedTask.status)
                                              : const SizedBox.shrink(),
                                          const SizedBox(height: 10),
                                          _bottomButtonsApproval(
                                              assignedTask.status),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const Text(
                                              'Task has not been started.'),
                                          const SizedBox(height: 15),
                                          ElevatedButton(
                                            onPressed: () async {
                                              await firebaseFunctions.startTask(
                                                  widget.topicId,
                                                  widget.taskId);
                                              ref.invalidate(
                                                  taskWrittenProvider);

                                              print('call task start shiii');
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
                                            child: const Text(
                                              'Start task now',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                              ],
                            );
                          },
                          error: (error, stack) =>
                              Center(child: Text('Error: $error')),
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              isContentSubmitted
                  ? const LoadingScreen(
                      customMessage: 'Loading...',
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  IconButton _timelineButton(BuildContext context, ViewedTask assignedTask) {
    return IconButton(
      icon: const Icon(
        Icons.history,
        color: Color(0xFF020B40),
      ),
      onPressed: FirebaseAuth.instance.currentUser != null
          ? () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TimelineV2Page(
                    topicId: widget.topicId,
                    title: assignedTask.title,
                    sectionName: widget.section,
                    deadline: assignedTask.deadline,
                    totalSubtask: assignedTask.totalSubtask,
                    projectStep: assignedTask.projectStep,
                  ),
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
    );
  }

  FutureBuilder<bool> _commentContainer() {
    return FutureBuilder<bool>(
      future: _canUserEditFuture,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final userCanEdit = snapshot.data!;
          return TextFormField(
            controller: _commentController,
            keyboardType: TextInputType.multiline,
            maxLines: 8,
            cursorColor: const Color(0XFF020B40),
            readOnly: !userCanEdit,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0XFFF5F5F5),
              labelText: userCanEdit
                  ? 'Leave your comments here and return the work for revision.'
                  : "Comments about your work from your section editor will be placed here.",
              labelStyle: const TextStyle(
                color: Color(0xFF020B40),
                fontSize: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0XFF020B40),
                ),
              ),
              suffixIcon: userCanEdit
                  ? IconButton(
                      icon: const Icon(Icons.send_rounded),
                      color: const Color(0xFF020B40),
                      onPressed: () async {
                        final comment = _commentController.text.trim();

                        if (comment.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter a comment first.')),
                          );
                          return;
                        }

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: const Text('Confirm Action'),
                              content: const Text(
                                'Are you sure you want to return this task to the creator with your comments?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: const Text('Confirm'),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirm == true) {
                          ref.invalidate(taskWrittenProvider);
                          await firebaseFunctions.seReject(
                            widget.topicId,
                            widget.taskId,
                            comment,
                            _contentController.text,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task returned successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          print('Sending comment: $comment');
                          print('content is: ${_contentController.text}');
                        }
                      },
                    )
                  : null,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the topic details';
              }
              return null;
            },
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  FutureBuilder<bool> _bottomButtonsApproval(String taskStatus) {
    return FutureBuilder<bool>(
      future: _canUserEditFuture,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.hasData) {
          final userCanEdit = snapshot.data!;
          return userCanEdit
              ? taskStatus == 'Approved' || taskStatus == 'Done'
                  ? const Text(
                      'Task has been approved already',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    )
                  : _adminButtoms()
              : const SizedBox.shrink();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}'); // Handle error appropriately
        } else {
          return const CircularProgressIndicator(); // Show loading indicator
        }
      },
    );
  }

  FutureBuilder<bool> _bottomButtons(String taskStatus) {
    return FutureBuilder(
      future: _canUserEditFuture,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.hasData) {
          final userCanEdit = snapshot.data!;

          return userCanEdit == false
              ? taskStatus == "Submitted" ||
                      taskStatus == "Approved" ||
                      taskStatus == 'Done'
                  ? const Text(
                      'No futher edits can be done to this task if its finished',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    )
                  : _submissionButtons(context)
              : _submissionButtons(context);
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

  Row _submissionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirm Task Submission'),
                      content: const Text(
                          'Are you sure you want to submit this task?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pop(false), // No
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop(true); // Yes
                          },
                          child: switch (widget.type) {
                            'Writing' => const Text('Submit'),
                            'Photography' => const Text('Submit'),
                            'Pubmat' => const Text('Submit'),
                            _ => const SizedBox.shrink()
                          },
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  try {
                    switch (widget.type) {
                      case 'Writing':
                        setState(() {
                          isContentSubmitted = true;
                          wasSubmitPressed = true;
                          FocusScope.of(context).unfocus();
                        });
                        await firebaseFunctions.submitSubTaskContent(
                          widget.topicId,
                          widget.taskId,
                          _headlineController.text,
                          _contentController.text,
                        );
                        setState(() {
                          isContentSubmitted = false;
                          wasSubmitPressed = true;
                        });
                        break;
                      case 'Photography':
                        print('call caption submission');
                        break;
                    }

                    ref.invalidate(taskWrittenProvider);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Task submitted successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to submit task: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
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
                'Submit content!',
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
    );
  }

  Row _writingInput() {
    return Row(
      children: [
        Expanded(
          child: ValueListenableBuilder<String>(
            valueListenable: _contentNotifier,
            builder: (context, value, child) {
              return TextFormField(
                controller: _contentController,
                keyboardType: TextInputType.multiline,
                maxLines: 8,
                cursorColor: const Color(0XFF020B40),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0XFFF5F5F5),
                  labelText: 'Content',
                  labelStyle: const TextStyle(
                    color: Color(0xFF020B40),
                    fontSize: 12,
                  ),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0XFF020B40),
                    ),
                  ),
                  focusColor: const Color(0XFF020B40),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.fullscreen),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullscreenTextPage(
                            contentNotifier: _contentNotifier,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                validator: (text) {
                  if (text == null || text.isEmpty) {
                    return 'Please enter the topic content';
                  }
                  return null;
                },
                onChanged: (text) {
                  _contentNotifier.value = text; // Update the notifier
                },
              );
            },
          ),
        ),
      ],
    );
  }

  TextFormField _captionInput() {
    return TextFormField(
      controller: _captionController,
      keyboardType: TextInputType.multiline,
      maxLines: 2,
      cursorColor: const Color(0XFF020B40),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0XFFF5F5F5),
        labelText: 'Caption',
        labelStyle: const TextStyle(
          color: Color(0xFF020B40),
          fontSize: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Color(0XFF020B40),
          ),
        ),
        focusColor: const Color(0XFF020B40),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the topic headline';
        }

        return null;
      },
    );
  }

  Align _captionLabel() {
    return const Align(
      alignment: Alignment.topLeft,
      child: Text(
        'Caption',
        style: TextStyle(
          color: Colors.black,
          fontSize: 15,
        ),
      ),
    );
  }

  Future<bool> _showDiscardConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Discard Changes?'),
          content: const Text(
              'Are you sure you want to leave? Any unsaved changes will be lost.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Stay on page
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Leave page
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
    // If the dialog is dismissed by tapping outside, result will be null.
    // Treat null as 'false' (don't pop).
    return result ?? false;
  }

  Row _adminButtoms() {
    return Row(
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
                      'Are you sure you want to approve this submission?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false), // No
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true), // Yes
                      child: const Text('Approve'),
                    ),
                  ],
                );
              },
            );

            if (confirm == true) {
              try {
                print('submission accepted');
                await firebaseFunctions.seApprove(
                    widget.topicId, widget.taskId);
                ref.invalidate(taskWrittenProvider);

                // Show success SnackBar
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Submission approved successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (error) {
                // Show failure SnackBar
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to approve submission: $error'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Rounded corners
            ),
            elevation: 10, // Add elevation for shadow
            padding: const EdgeInsets.symmetric(
                vertical: 15.0, horizontal: 20.0), // Padding for the button
          ),
          child: const Text(
            'Accept',
            style: TextStyle(
              color: Colors.white, // White text color
              fontWeight: FontWeight.w700, // Bold text
            ),
          ),
        ),
      ],
    );
  }

  Row _buildImageInput(
      BuildContext context, AsyncValue<List<String>> retImagesView) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            print('image selected');
            _showUploadSection(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF020B40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Rounded corners
            ),
            elevation: 10, // Add elevation for shadow
            padding: const EdgeInsets.symmetric(
                vertical: 15.0, horizontal: 20.0), // Padding for the button
          ),
          child: const Text(
            'Add Photos',
            style: TextStyle(
              color: Colors.white, // White text color
              fontWeight: FontWeight.w700, // Bold text
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            print('images shown');
            if (mounted) {
              _showImageSection(context, showImageIsLoading, retImagesView);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF020B40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Rounded corners
            ),
            elevation: 10, // Add elevation for shadow
            padding: const EdgeInsets.symmetric(
                vertical: 15.0, horizontal: 20.0), // Padding for the button
          ),
          child: const Text(
            'Show Images',
            style: TextStyle(
              color: Colors.white, // White text color
              fontWeight: FontWeight.w700, // Bold text
            ),
          ),
        ),
      ],
    );
  }

  TextFormField _headlineInput() {
    return TextFormField(
      controller: _headlineController,
      keyboardType: TextInputType.multiline,
      maxLines: 2,
      cursorColor: const Color(0XFF020B40),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0XFFF5F5F5),
        labelText: 'Headline',
        labelStyle: const TextStyle(
          color: Color(0xFF020B40),
          fontSize: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Color(0XFF020B40),
          ),
        ),
        focusColor: const Color(0XFF020B40),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the topic headline';
        }

        return null;
      },
    );
  }

  Align _headlineLabel() {
    return const Align(
      alignment: Alignment.topLeft,
      child: Text(
        'Headline',
        style: TextStyle(
          color: Colors.black,
          fontSize: 15,
        ),
      ),
    );
  }

  void _showUploadSection(BuildContext context) {
    Map<String, double> uploadProgress = {};
    List<String> uploadingImagePaths = [];
    bool isUploading = false;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Stack(
                children: [
                  FractionallySizedBox(
                    heightFactor: 0.90,
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
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  MultiImagePickerView(
                                    controller: controller,
                                    builder: (context, imageFile) {
                                      return Stack(
                                        children: [
                                          DefaultDraggableItemWidget(
                                            imageFile: imageFile,
                                            boxDecoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            closeButtonAlignment:
                                                Alignment.topLeft,
                                            fit: BoxFit.cover,
                                            closeButtonIcon: const Icon(
                                              Icons.delete_rounded,
                                              color: Colors.red,
                                            ),
                                            closeButtonBoxDecoration: null,
                                            closeButtonMargin:
                                                const EdgeInsets.all(3),
                                            closeButtonPadding:
                                                const EdgeInsets.all(3),
                                          ),
                                          uploadProgress.containsKey(
                                                      imageFile.path) &&
                                                  isUploading
                                              ? Positioned.fill(
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: uploadProgress[
                                                                imageFile
                                                                    .path] ==
                                                            1.0
                                                        ? const Icon(
                                                            Icons.check_circle,
                                                            color: Colors.green,
                                                            size: 30)
                                                        : const CircularProgressIndicator(),
                                                  ),
                                                )
                                              : const SizedBox(), // Instead of showing the progress bar early, show nothing.
                                        ],
                                      );
                                    },
                                    initialWidget: const DefaultInitialWidget(
                                      centerWidget:
                                          Icon(Icons.image_search_outlined),
                                      backgroundColor: Colors.grey,
                                      margin: EdgeInsets.all(0),
                                    ),
                                    addMoreButton: const DefaultAddMoreWidget(
                                      icon: Icon(Icons.image_search_outlined),
                                      backgroundColor: Colors.grey,
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    shrinkWrap: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                isUploading = true;
                                wasSubmitPressed = true;
                              });
                              widget.type == 'Photography'
                                  ? await _uploadImages(setModalState,
                                      uploadProgress, uploadingImagePaths)
                                  : await _uploadMultiPubmat(setModalState,
                                      uploadProgress, uploadingImagePaths);

                              ref.invalidate(singleViewTopicContent);

                              print('uploading images');
                              // Call your Firebase Storage upload function here
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF020B40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 10,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15.0, horizontal: 30.0),
                            ),
                            child: const Text(
                              'Upload To Storage',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        });
  }

  void _showImageSection(BuildContext context, bool isLoading,
      AsyncValue<List<String>> retImagesView) async {
    // Get the image URLs first
    List<String> imagesToShow = retImagesView.asData?.value ?? [];

    // --- Conditional Similarity Check ---
    if (widget.type == 'Photography') {
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
            return _buildImageGrid(modalContext, const AsyncValue.data([]), {});
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
                                modalContext, retImagesView, similarImagesMap);
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
              return _buildImageGrid(modalContext, retImagesView, {});
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
              return _buildImageGrid(modalContext, retImagesView, {});
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
          return _buildImageGrid(modalContext, retImagesView, {});
        },
      );
    }
  }

  Widget _buildImageGrid(
      BuildContext modalContext, // Use the modal's context
      AsyncValue<List<String>> retImagesView,
      Map<String, List<String>> similarImagesMap) {
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
                              if (isSimilar &&
                                  widget.type ==
                                      'Photography') // Check type here too
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
}
