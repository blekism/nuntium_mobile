import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_image_picker_view/multi_image_picker_view.dart';
import 'package:nuntium_mobile/Pages/Eic/fullscreentextfield.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/image_processor/image_upload_service.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class InstantCreate extends ConsumerStatefulWidget {
  final String pageType;
  final String? creatorSection;

  const InstantCreate({
    super.key,
    required this.pageType,
    this.creatorSection,
  });

  @override
  ConsumerState<InstantCreate> createState() => _InstantCreateState();
}

class _InstantCreateState extends ConsumerState<InstantCreate> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _headlineController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final firebaseFunctions = FirebaseFunctions();
  final ValueNotifier<String> _contentNotifier = ValueNotifier<String>('');
  final ImageUploadService imageUploadService = ImageUploadService();
  bool showImageIsLoading = true;
  bool isContentSubmitted = false;
  bool wasSubmitPressed = false;
  Map<String, double> uploadProgress = {};
  List<String> uploadingImagePaths = [];
  bool isUploading = false;
  String? _selectedSectionID;
  final String _photographySectionId = 'XDEPw2VPYdeFdKQRuRpA';

  final controller = MultiImagePickerController(
    maxImages: 10,
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

  Future<List<String>> _uploadMultiPubmat(
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
            setState(() {
              uploadProgress[fileWrapper.path!] = progress;
            });

            print("Upload Progress: $progress");
            // Update your UI with the progress (e.g., a progress bar)
          }, onError: (error) {
            print("Error listening to snapshot events: $error");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error monitoring upload: $error")),
            );
            // Remove the image path from the list of uploading images in case of error
            uploadingImagePaths.remove(fileWrapper.path!);
            setState(() {}); // Update UI to remove progress indicator
          }, onDone: () {
            // Remove the image path from the list of uploading images when done
            uploadingImagePaths.remove(fileWrapper.path!);
            setState(() {}); // Update UI to remove progress indicator
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
          setState(() {}); // Update UI to remove progress indicator
          return []; // Or continue; if you want to try other images
        }
      }
    }

    print("Image URLs: $imageUrls");

    // images will go directly to posts collection
    print("Images uploaded successfully!");
    return imageUrls;
  }

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

    if (widget.pageType == 'photography') {
      _selectedSectionID = _photographySectionId;
    } else if (widget.creatorSection != null) {
      _selectedSectionID = widget.creatorSection;
    }
  }

  @override
  void dispose() {
    _contentNotifier
        .dispose(); // Dispose of the ValueNotifier when the widget is disposed
    _headlineController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = ref.watch(sectionProvider);
    final bool isDropdownReadOnly;
    if (widget.pageType == 'photography') {
      isDropdownReadOnly =
          true; // Photography page always has a read-only, specific section
    } else if (widget.creatorSection != null) {
      isDropdownReadOnly =
          true; // Creator section provided for non-photography types makes it read-only
    } else {
      isDropdownReadOnly = false; // Otherwise, it's editable
    }

    return Scaffold(
      appBar: const CustomAppBar(
        hasNavigated: false,
        appbarTitle: 'Create a New Post',
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Section',
                      style: TextStyle(
                        color: Color(0xFF020B40),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  sections.when(
                    data: (sections) {
                      final docs = sections.docs;
                      String? currentSelectedSectionNameForDisplay;

                      if (_selectedSectionID != null) {
                        try {
                          final selectedDoc = docs.firstWhere(
                              (doc) => doc.id == _selectedSectionID,
                              orElse: () => throw Exception(
                                  'Selected section ID not found in list')); // Added orElse for safety
                          currentSelectedSectionNameForDisplay = (selectedDoc
                              .data() as Map<String, dynamic>)['sectionType'];
                        } catch (e) {
                          print(
                              "Error finding section name for ID '$_selectedSectionID': $e");
                          // Fallback or specific handling if section ID from props isn't in the fetched list
                          if (widget.pageType == 'photography' &&
                              _selectedSectionID == _photographySectionId) {
                            currentSelectedSectionNameForDisplay =
                                "Photography"; // Default name if not found
                          } else if (widget.creatorSection ==
                                  _selectedSectionID &&
                              widget.creatorSection != null) {
                            // If creatorSection was provided but not found, this is a data inconsistency.
                            // For now, show ID or a generic name.
                            currentSelectedSectionNameForDisplay =
                                "Section (ID: $_selectedSectionID)";
                          } else {
                            currentSelectedSectionNameForDisplay =
                                "Unknown Section";
                          }
                        }
                      }

                      return DropdownButtonFormField<String>(
                        value: _selectedSectionID,
                        items: isDropdownReadOnly &&
                                currentSelectedSectionNameForDisplay != null &&
                                _selectedSectionID != null
                            ? [
                                // If read-only and a section is selected, show only that item
                                DropdownMenuItem<String>(
                                  value: _selectedSectionID!,
                                  child: Text(
                                      currentSelectedSectionNameForDisplay),
                                ),
                              ]
                            : docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final name = data['sectionType'] ?? 'unknown';
                                return DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text(name),
                                );
                              }).toList(),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDropdownReadOnly
                              ? Colors.grey[300] // Indicate disabled state
                              : const Color(0XFFF5F5F5),
                          labelText: 'Section',
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
                        ),
                        onChanged: isDropdownReadOnly
                            ? null // Disable dropdown if photography page
                            : (value) {
                                setState(() {
                                  _selectedSectionID = value;
                                });
                              },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select Topic section';
                          }
                          return null;
                        },
                        // Read-only visual cue for photography page
                        disabledHint: isDropdownReadOnly &&
                                currentSelectedSectionNameForDisplay != null
                            ? Text(currentSelectedSectionNameForDisplay)
                            : null,
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stackTrace) => Text('Error: $error'),
                  ),
                  widget.pageType == 'article'
                      ? _instantArticle()
                      : _instantPhotojourn(),
                  const SizedBox(height: 10),
                  _buildImageInput(context),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          isUploading = true;
                          wasSubmitPressed = true;
                        });

                        List<String> imageUrls =
                            await _uploadMultiPubmat(uploadingImagePaths);

                        setState(() {
                          isUploading = false;
                        });

                        if (imageUrls.isNotEmpty) {
                          if (widget.pageType == 'article') {
                            await firebaseFunctions.instantPost(
                              imageUrls,
                              _headlineController.text,
                              _contentController.text,
                              _selectedSectionID,
                            );
                          } else {
                            await firebaseFunctions.instantPhotoPost(
                              imageUrls,
                              _captionController.text,
                              _selectedSectionID,
                            );
                          }
                        } else {
                          // Handle the case where no images were uploaded (optional)
                          print('No images uploaded.');
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
                    child: isUploading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text(
                            'Create the post',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Column _instantArticle() {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Headline: ',
            style: TextStyle(
              color: Color(0xFF020B40),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: _headlineController,
          cursorColor: const Color(0XFF020B40),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0XFFF5F5F5),
            labelText: 'Title',
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
        ),
        const SizedBox(height: 10),
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
        _writingInput()
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

  Column _instantPhotojourn() {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Caption',
            style: TextStyle(
              color: Color(0xFF020B40),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextFormField(
          controller: _captionController,
          cursorColor: const Color(0XFF020B40),
          maxLines: 15,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0XFFF5F5F5),
            labelText: 'Caption',
            labelStyle: const TextStyle(
              color: Color(0xFF020B40),
              fontSize: 8,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
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
              return 'Please enter the caption';
            }

            return null;
          },
        ),
      ],
    );
  }

  Row _buildImageInput(BuildContext context) {
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
      ],
    );
  }

  void _showUploadSection(BuildContext context) {
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
                                          GestureDetector(
                                            onTap: () {
                                              final imageList =
                                                  controller.images.toList();
                                              final images = imageList
                                                  .map((e) => File(e.path!))
                                                  .toList();
                                              final index =
                                                  imageList.indexWhere((img) =>
                                                      img.path ==
                                                      imageFile.path);
                                              if (index != -1) {
                                                _openFullScreenLocal(
                                                    context, index, images);
                                              }
                                            },
                                            child: DefaultDraggableItemWidget(
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
                                          ),
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

  void _openFullScreenLocal(
      BuildContext context, int index, List<File> images) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: PhotoViewGallery.builder(
            itemCount: images.length,
            builder: (context, pageIndex) => PhotoViewGalleryPageOptions(
              imageProvider: FileImage(images[pageIndex]),
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
