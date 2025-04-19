import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/Eic/assign_task_page.dart';
import 'package:nuntium_mobile/Pages/Eic/fullscreentextfield.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/image_processor/image_upload_service.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker_view/multi_image_picker_view.dart';

class DoAssignedTaskPage extends ConsumerStatefulWidget {
  final String topicId, taskId, section, sectionId, type;

  const DoAssignedTaskPage({
    super.key,
    required this.topicId,
    required this.taskId,
    required this.section,
    required this.sectionId,
    required this.type,
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
  File? _selectedSingleImage;
  bool _isUploading = false;
  bool _uploadSuccess = false;

  @override
  void initState() {
    super.initState();
    _contentController.text = _contentNotifier.value; // Set initial value

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

  Future<void> _pickSingleImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedSingleImage = File(image.path);
      });
    }
  }

  Future<String?> uploadSingleImage(File selectedImage) async {
    try {
      final String? userId = firebaseFunctions.auth.currentUser?.uid;
      if (userId == null) {
        print("User not logged in.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in.")),
        );
        return null;
      }

      final storagePath =
          'images/${widget.topicId}_${DateTime.now().millisecondsSinceEpoch}';

      final Reference storageRef = FirebaseStorage.instance.ref(storagePath);

      final UploadTask uploadTask = storageRef.putFile(selectedImage);

      await uploadTask.whenComplete(() => print('Image uploaded'));

      final String downloadURL = await storageRef.getDownloadURL();
      print('File available at $downloadURL');
      return downloadURL;
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e")),
      );
      return null;
    }
  }

  Future<void> deleteImage(int index, List<String> retrievedImages) async {
    try {
      await firebaseFunctions.deleteImages(
        index,
        retrievedImages,
        widget.topicId,
        widget.taskId,
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
    final assignedTaskView =
        ref.watch(taskWrittenProvider((widget.topicId, widget.taskId)));
    final canUserEdit =
        firebaseFunctions.canUserEdit(firebaseFunctions.auth.currentUser!.uid);
    final retImagesView =
        ref.watch(retImagesProvider((widget.topicId, widget.taskId)));

    return Scaffold(
      appBar: const CustomAppBar(
        appbarTitle: 'Create Your Content',
        hasNavigated: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                assignedTaskView.when(
                  data: (assignedTask) {
                    _headlineController.text = assignedTask.headline;
                    _contentNotifier.value = assignedTask.content;
                    _contentController.text = assignedTask.content;

                    return Column(
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
                              builder: (BuildContext context,
                                  AsyncSnapshot<bool> snapshot) {
                                if (snapshot.hasData) {
                                  final userCanEdit =
                                      snapshot.data!; // Safely unwrap the bool

                                  return userCanEdit
                                      ? Align(
                                          alignment: Alignment.topRight,
                                          child: IconButton(
                                            onPressed: () {
                                              print(
                                                  'editing this ${assignedTask.deadline}');
                                              print(
                                                  'editing this ${assignedTask.assignee}');
                                              print(
                                                  'editing this ${assignedTask.title}');
                                              print(
                                                  'editing this ${assignedTask.tasktype}');
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AssignTaskPage(
                                                    isEditing: true,
                                                    deadline:
                                                        assignedTask.deadline,
                                                    member:
                                                        assignedTask.assignee,
                                                    taskname:
                                                        assignedTask.title,
                                                    tasktype:
                                                        assignedTask.tasktype,
                                                    sectionId: assignedTask
                                                        .assigneeSec,
                                                    topicId: widget.topicId,
                                                    taskId: assignedTask.taskId,
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
                            ' Created by: ${assignedTask.assigner} | ${assignedTask.priority}',
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
                        const SizedBox(height: 15),
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
                              retImagesView,
                            ),
                          'Pubmat' => Align(
                              alignment: Alignment.center,
                              child: GestureDetector(
                                onTap: () async {
                                  print('image selection opened');

                                  assignedTask.content != '' &&
                                          assignedTask.content
                                              .startsWith('http')
                                      ? print('may image na tanga')
                                      : await _pickSingleImage();
                                },
                                child: Align(
                                  alignment: Alignment.center,
                                  child: assignedTask.content != '' &&
                                          assignedTask.content
                                              .startsWith('http')
                                      ? AspectRatio(
                                          aspectRatio: 1,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Stack(
                                              children: [
                                                Image.network(
                                                  assignedTask.content,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return const Text(
                                                        'Failed to load image');
                                                  },
                                                ),
                                                Positioned(
                                                  top: 8,
                                                  left: 8,
                                                  child: GestureDetector(
                                                    onTap: () async {
                                                      setState(() {
                                                        _selectedSingleImage =
                                                            null;
                                                      });

                                                      await firebaseFunctions
                                                          .deleteImage(
                                                        widget.topicId,
                                                        widget.taskId,
                                                        assignedTask.content,
                                                      );

                                                      ref.invalidate(
                                                          taskWrittenProvider);
                                                    },
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withOpacity(0.5),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets.all(4.0),
                                                        child: Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        )
                                      : _selectedSingleImage == null
                                          ? Container(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  .3,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  .85,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: DottedBorder(
                                                color: const Color(0XFF020B40),
                                                borderType: BorderType.RRect,
                                                radius:
                                                    const Radius.circular(10),
                                                strokeWidth: 2,
                                                child: const Center(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                          'Select your pubmat image'),
                                                      SizedBox(width: 5),
                                                      Icon(Icons
                                                          .add_circle_outline)
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            )
                                          : _isUploading
                                              ? const CircularProgressIndicator()
                                              : ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Stack(
                                                    children: [
                                                      Image.file(
                                                        _selectedSingleImage!,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            .85,
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            .3,
                                                        fit: BoxFit.cover,
                                                      ),
                                                      Positioned(
                                                        top: 8,
                                                        left: 8,
                                                        child: GestureDetector(
                                                          onTap: () async {
                                                            setState(() {
                                                              _selectedSingleImage =
                                                                  null;
                                                            });

                                                            await firebaseFunctions
                                                                .deleteImage(
                                                              widget.topicId,
                                                              widget.taskId,
                                                              assignedTask
                                                                  .content,
                                                            );

                                                            ref.invalidate(
                                                                taskWrittenProvider);
                                                          },
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.5),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child:
                                                                const Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(4.0),
                                                              child: Icon(
                                                                Icons.close,
                                                                color: Colors
                                                                    .white,
                                                                size: 20,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                ),
                              ),
                            ),
                          _ => const SizedBox.shrink(),
                        },
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 60,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text(
                                              'Confirm Task Submission'),
                                          content: const Text(
                                              'Are you sure you want to submit this task?'),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false), // No
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.of(context)
                                                    .pop(true); // Yes
                                              },
                                              child: switch (widget.type) {
                                                'Writing' =>
                                                  const Text('Submit'),
                                                'Photography' => const Text(
                                                    'Submit the Caption'),
                                                'Pubmat' =>
                                                  const Text('Submit'),
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
                                            await firebaseFunctions
                                                .submitSubTaskContent(
                                              widget.topicId,
                                              widget.taskId,
                                              _headlineController.text,
                                              _contentController.text,
                                            );
                                            break;
                                          case 'Photography':
                                            print('call caption submission');
                                            break;
                                          case 'Pubmat':
                                            setState(() {
                                              _isUploading = true;
                                              _uploadSuccess = false;
                                            });
                                            if (_selectedSingleImage != null) {
                                              final imageUrl =
                                                  await uploadSingleImage(
                                                      _selectedSingleImage!);
                                              if (imageUrl != null) {
                                                // Now you have the imageUrl, you can save it to Firestore or use it as needed
                                                print(
                                                    'Uploaded image URL: $imageUrl');
                                                // call firebase function to save the pubmat url
                                                await firebaseFunctions
                                                    .pubmatImageUpload(
                                                  widget.topicId,
                                                  widget.taskId,
                                                  imageUrl,
                                                );
                                                setState(() {
                                                  _isUploading = false;
                                                  _uploadSuccess = true;
                                                });
                                              } else {
                                                // Handle the error case where the image upload failed
                                                print('Image upload failed');
                                                setState(() {
                                                  _isUploading = false;
                                                  _uploadSuccess = false;
                                                });
                                              }
                                            } else {
                                              print('No image selected');
                                              setState(() {
                                                _isUploading = false;
                                                _uploadSuccess = false;
                                              });
                                            }
                                            break;
                                        }

                                        ref.invalidate(taskWrittenProvider);

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Task submitted successfully!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (error) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Failed to submit task: $error'),
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
                                    'Submit!',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 60,
                              child: ElevatedButton(
                                onPressed: () async {
                                  showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Confirm Discard'),
                                        content: const Text(
                                            'Are you sure you want to discard this task? Any unsaved changes will be lost.'),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('Discard'),
                                          ),
                                        ],
                                      );
                                    },
                                  ).then((value) {
                                    if (value == true) {
                                      // Handle discard logic here, e.g., navigate back
                                      Navigator.pop(context);
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0XFFDDDDDD),
                                  elevation: 10,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Discard',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0XFF020B40),
                                    ),
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
              ],
            ),
          ),
        ),
      ),
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
                              });
                              _uploadImages(setModalState, uploadProgress,
                                  uploadingImagePaths);

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
    // Make it async
    // Show loading dialog immediately when the bottom sheet is opened
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

    // Get the image URLs
    List<String> imagesToShow = [];
    retImagesView.whenData((data) => imagesToShow = data);

    // Perform the similarity check
    final imageUploadService = ImageUploadService();

    final Map<String, List<String>> similarImagesMap =
        await imageUploadService.findSimilarExistingImages(imagesToShow);

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
                            modalContext, retImagesView, similarImagesMap);
                      },
                    );
                  },
                ),
              ]);
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
          return _buildImageGrid(modalContext, retImagesView, similarImagesMap);
        },
      );
    }
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
