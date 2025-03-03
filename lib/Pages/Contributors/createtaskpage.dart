import 'package:flutter/material.dart';
import '../Contributors/Templates/timelinetabtemplate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker_view/multi_image_picker_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class CreateTaskPage extends StatefulWidget {
  final String? taskId;
  final String? details;
  final String? title;
  final String? taskType;
  final String? assignedId;
  final String? clickOrigin;

  const CreateTaskPage({
    super.key,
    required this.taskId,
    required this.details,
    required this.title,
    required this.taskType,
    this.assignedId,
    this.clickOrigin,
  });

  @override
  State<CreateTaskPage> createState() => _CreateTaskPage();
}

class _CreateTaskPage extends State<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _taskTypeController = TextEditingController();
  final TextEditingController _taskDetailsController = TextEditingController();
  final TextEditingController _taskContentController = TextEditingController();
  bool showImageIsLoading = true;
  List<String> retrievedImages = [];

  final controller = MultiImagePickerController(
    maxImages: 200,
    picker: (allowMultiple) async {
      final pickedFiles = await ImagePicker().pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
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

  Future<void> _uploadImages() async {
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

        try {
          // 1. Listen for upload progress (Stream)
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            double progress = snapshot.bytesTransferred / snapshot.totalBytes;
            print("Upload Progress: $progress");
            // Update your UI with the progress (e.g., a progress bar)
          }, onError: (error) {
            print("Error listening to snapshot events: $error");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error monitoring upload: $error")),
            );
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
          return; // Or continue; if you want to try other images
        }
      }
    }

    print("Image URLs: $imageUrls");

    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskId)
        .collection('assigned_tasks')
        .doc(widget.assignedId)
        .update({
      'submitted_at': FieldValue.serverTimestamp(),
      'images': FieldValue.arrayUnion(imageUrls),
    });
    print("Images uploaded successfully!");
  }

  Future<void> _retrieveImages() async {
    print('click origin is ${widget.clickOrigin}');
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .collection('assigned_tasks')
          .doc(widget.assignedId)
          .get();

      if (snapshot.exists) {
        List<dynamic> images = snapshot['images'];
        setState(() {
          retrievedImages = images.cast<String>();
          showImageIsLoading = false;
        });
      }
    } catch (e) {
      print("Error retrieving images: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _taskTitleController.text = widget.title!;
    _taskTypeController.text = widget.taskType!;
    _taskDetailsController.text = widget.details!;

    if (widget.taskId != null) {
      fetchLatestContent(widget.taskId!);
    }
  }

  Future<void> submitContent(
      String taskId, String content, String userId) async {
    try {
      // Reference to the assigned_tasks subcollection for the specific task
      var assignedTasksRef = FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .collection('assigned_tasks')
          .doc(widget.assignedId);

      var timelineRef = FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .collection('timeline');

      var assignedTaskSnapshot = await assignedTasksRef.get();
      bool isRevised =
          assignedTaskSnapshot.exists; //uf existing, its a revision

      var timelineSnapshot = await timelineRef.get();

      int revisionNumber = timelineSnapshot.docs.length;

      await assignedTasksRef.update({
        'content': content,
        'submitted_at': FieldValue.serverTimestamp(),
      });

      // Add to the timeline_history subcollection
      await timelineRef.add({
        'comment': isRevised ? 'No comments yet' : 'Content submitted',
        'content': content,
        'date': FieldValue.serverTimestamp(),
        'revision': 'Revision ${revisionNumber + 1}',
        'timelinestatus': isRevised ? 'revised' : 'submitted',
      });

      print("Content and timeline history logged successfully!");
      fetchLatestContent(taskId);
    } catch (e) {
      print("Error submitting content and logging timeline history: $e");
    }
  }

  Future<void> fetchLatestContent(String taskId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .collection('assigned_tasks')
          .orderBy('submitted_at', descending: true) // Get latest content
          .limit(1) // Fetch only the latest entry
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _taskContentController.text = snapshot.docs.first['content'];
        });
      }
    } catch (e) {
      print("Error fetching content: $e");
    }
  }

  Future<void> deleteImage(int index) async {
    try {
      String imageUrl = retrievedImages[index];

      Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);

      await storageRef.delete();
      print('Image deleted from storage');

      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId)
          .collection('assigned_tasks')
          .doc(widget.assignedId)
          .update({
        'images': FieldValue.arrayRemove([retrievedImages[index]]),
      });
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(35),
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Task Title',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _taskTitleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: const TextStyle(
                        color: Color(0xFF020B40),
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: const Color(0xFff5f5f5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0XFF020B40),
                        ),
                      ),
                    ),
                    readOnly: true,
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter task title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Task Type',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _taskTypeController,
                    decoration: InputDecoration(
                      labelText: 'Task Type',
                      labelStyle: const TextStyle(
                        color: Color(0xFF020B40),
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: const Color(0xFff5f5f5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0XFF020B40),
                        ),
                      ),
                    ),
                    readOnly: true,
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter task title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Task Details',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _taskDetailsController,
                    maxLines: 2,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: const TextStyle(
                        color: Color(0xFF020B40),
                        fontSize: 16,
                      ),
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: const Color(0xFff5f5f5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0XFF020B40),
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter task title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  widget.taskType == 'writing'
                      ? _writeTaskType()
                      : _buildImageInput(),

                  const SizedBox(height: 15),
                  widget.taskType == 'writing'
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {
                              if (widget.taskId != null) {
                                submitContent(widget.taskId!,
                                    _taskContentController.text, 'userId');
                              } else {
                                print("Error: taskId is null");
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF020B40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    10), // Rounded corners
                              ),
                              elevation: 10, // Add elevation for shadow
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15.0,
                                  horizontal: 30.0), // Padding for the button
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                color: Colors.white, // White text color
                                fontWeight: FontWeight.w700, // Bold text
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),

                  // dito yung button for timeline
                  const SizedBox(height: 15),

                  TimelineTab(
                    taskId: widget.taskId,
                    taskTitle: widget.title,
                    taskDescription: widget.details,
                  ),
                  const SizedBox(height: 15),

                  const Text(
                    'Comments',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    // controller: _fname,
                    decoration: InputDecoration(
                      labelText: 'Comments',
                      labelStyle: const TextStyle(
                        color: Color(0xFF020B40),
                        fontSize: 16,
                      ),
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: const Color(0xFff5f5f5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0XFF020B40),
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: 5,
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter task title';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () {
          Navigator.pop(context); // Navigate back to the previous screen
        },
      ),
      title: const Text(
        'Ongoing Task',
        style: TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
    );
  }

  TextFormField _writeTaskType() {
    return TextFormField(
      controller: _taskContentController,
      decoration: InputDecoration(
        labelText: 'Content',
        labelStyle: const TextStyle(
          color: Color(0xFF020B40),
          fontSize: 16,
        ),
        filled: true,
        fillColor: const Color(0xFff5f5f5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Color(0XFF020B40),
          ),
        ),
      ),
      keyboardType: TextInputType.multiline,
      maxLines: null,
      style: const TextStyle(
        color: Colors.black,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter task title';
        }
        return null;
      },
    );
  }

  Widget _buildImageInput() {
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
            await _retrieveImages();
            if (mounted) {
              _showImageSection(context, showImageIsLoading);
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

  void _showUploadSection(BuildContext context) {
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
                                  return DefaultDraggableItemWidget(
                                    imageFile: imageFile,
                                    boxDecoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    closeButtonAlignment: Alignment.topLeft,
                                    fit: BoxFit.cover,
                                    closeButtonIcon: const Icon(
                                      Icons.delete_rounded,
                                      color: Colors.red,
                                    ),
                                    closeButtonBoxDecoration: null,
                                    closeButtonMargin: const EdgeInsets.all(3),
                                    closeButtonPadding: const EdgeInsets.all(3),
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
                          _uploadImages();

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
        });
  }

  void _showImageSection(BuildContext context, bool isLoading) {
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
          builder: (context, setModalState) {
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
                          child: isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : retrievedImages.isEmpty
                                  ? const Center(
                                      child: Text('No images found'),
                                    )
                                  : GridView.builder(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3, // 3 columns
                                        crossAxisSpacing:
                                            10, // Horizontal spacing
                                        mainAxisSpacing: 10, // Vertical spacing
                                        childAspectRatio:
                                            1, // Square aspect ratio
                                      ),
                                      itemCount: retrievedImages.length,
                                      itemBuilder: (context, index) {
                                        return Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: () => _openFullScreen(
                                                  context, index),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        8), // Rounded corners
                                                child: Image.network(
                                                  retrievedImages[index],
                                                  fit: BoxFit
                                                      .cover, // Cover the square area
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 5,
                                              right: 5,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(
                                                      0.5), // Semi-transparent bg
                                                  shape: BoxShape.circle,
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_rounded,
                                                    color: Colors.white,
                                                    size:
                                                        20, // Adjust icon size
                                                  ),
                                                  onPressed: () async {
                                                    await deleteImage(index);
                                                    setModalState(() {});
                                                    // Handle delete functionality
                                                    print(
                                                        'Photo at index $index deleted');
                                                  },
                                                ),
                                              ),
                                            )
                                          ],
                                        );
                                      },
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
      },
    );
  }

  void _openFullScreen(BuildContext context, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: PhotoViewGallery.builder(
            itemCount: retrievedImages.length,
            builder: (context, pageIndex) => PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(retrievedImages[pageIndex]),
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
