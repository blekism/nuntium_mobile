import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/firebase_functions.dart';

class UploadTermlyPage extends ConsumerStatefulWidget {
  const UploadTermlyPage({super.key});

  @override
  ConsumerState<UploadTermlyPage> createState() => _UploadTermlyPageState();
}

class _UploadTermlyPageState extends ConsumerState<UploadTermlyPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final firebaseFunctions = FirebaseFunctions();
  String? _selectedSectionID;
  bool isUploading = false;
  bool wasSubmitPressed = false;
  File? _setSelectedImage;
  File? _setSelectedFile;
  String? _selectedFileName;

  Future<String?> uploadFile(File selectedFile) async {
    try {
      //for uploading both image and pdf
      final String? userId = firebaseFunctions.auth.currentUser?.uid;
      if (userId == null) {
        print("User not logged in.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in.")),
        );
        return null;
      }

      final storagePath = 'images/${DateTime.now().millisecondsSinceEpoch}';

      final Reference storageRef = FirebaseStorage.instance.ref(storagePath);

      final UploadTask uploadTask = storageRef.putFile(selectedFile);

      await uploadTask.whenComplete(() => print('File uploaded'));

      final String downloadURL = await storageRef.getDownloadURL();
      print('File available at $downloadURL');
      return downloadURL;
    } catch (e) {
      print("Error uploading File: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload file: $e")),
      );
      return null;
    }
  }

  Future<void> _pickSingleImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _setSelectedImage = File(image.path);
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Ensure only PDF can be picked
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _setSelectedFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name; // Store the file name
      });
      print("Picked file: ${result.files.single.path!}");
    } else {
      // User canceled the picker or path is null
      print("File picking cancelled or path was null.");
    }
  }

  Future<void> clearSelectedImage() async {
    setState(() {
      _setSelectedImage = null;
    });
    print('Selected image cleared');
  }

  Future<void> clearSelectedFile() async {
    // Add method to clear selected file
    setState(() {
      _setSelectedFile = null;
      _selectedFileName = null;
    });
    print('Selected file cleared');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        hasNavigated: false,
        appbarTitle: 'Termly Upload',
      ),
      body: GestureDetector(
        onTap: () {
          Focus.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Type',
                      style: TextStyle(
                        color: Color(0xFF020B40),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    onChanged: (String? newValue) {
                      _typeController.text = newValue!;
                    },
                    items: <String>[
                      'Magazine',
                      'Newsletter',
                      'Literary Folio',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0XFFF5F5F5),
                      labelText: 'Type',
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select Termly Category';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  _instantArticle(),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          isUploading = true;
                          wasSubmitPressed = true;
                        });

                        String? imageUrl = await uploadFile(_setSelectedImage!);
                        String? pdfUrl = await uploadFile(_setSelectedFile!);

                        setState(() {
                          isUploading = false;
                        });

                        if (imageUrl != null && pdfUrl != null) {
                          print('upload pedofile');
                          // call upload to firestore
                          await firebaseFunctions.postTermly(pdfUrl, imageUrl,
                              _typeController.text, _captionController.text);
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
                            'Post It Now!',
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
            'Title: ',
            style: TextStyle(
              color: Color(0xFF020B40),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: _captionController,
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
              return 'Please enter the topic title';
            }

            return null;
          },
        ),
        const SizedBox(height: 15),
        //gawing file input for pdf and for image separate
        GestureDetector(
          onTap: () async {
            if (_setSelectedImage == null) {
              await _pickSingleImage();
            } else {
              // Optionally, allow re-picking or clearing
              await clearSelectedImage(); // Example: tap again to clear
            }
          },
          child: _setSelectedImage != null
              ? Container(
                  width: MediaQuery.of(context).size.width * .8,
                  height: MediaQuery.of(context).size.height * .25,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0XFF020B40), width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                            8), // slightly less than container to see border
                        child: Image.file(
                          _setSelectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white,
                              shadows: [
                                Shadow(blurRadius: 2.0, color: Colors.black)
                              ]),
                          onPressed: clearSelectedImage,
                        ),
                      )
                    ],
                  ),
                )
              : Container(
                  width: MediaQuery.of(context).size.width * .8,
                  height: MediaQuery.of(context).size.height * .25,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DottedBorder(
                    color: const Color(0XFF020B40),
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(10),
                    strokeWidth: 2,
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Upload Thumbnail'),
                          SizedBox(width: 5),
                          Icon(Icons.add_circle_outline)
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: () async {
            if (_setSelectedFile == null) {
              await _pickFile();
            } else {
              // Optionally, allow re-picking or clearing
              await clearSelectedFile(); // Example: tap again to clear
            }
          },
          child: _setSelectedFile != null && _selectedFileName != null
              ? Container(
                  width: MediaQuery.of(context).size.width * .9,
                  height: MediaQuery.of(context).size.height * .1,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0XFF020B40), width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf,
                                color: Color(0XFF020B40)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedFileName!,
                                style:
                                    const TextStyle(color: Color(0XFF020B40)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0XFF020B40)),
                        onPressed: clearSelectedFile,
                      ),
                    ],
                  ),
                )
              : Container(
                  width: MediaQuery.of(context).size.width * .9,
                  height: MediaQuery.of(context).size.height * .1,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DottedBorder(
                    color: const Color(0XFF020B40),
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(10),
                    strokeWidth: 2,
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Upload PDF File'),
                          SizedBox(width: 5),
                          Icon(Icons.add_circle_outline)
                        ],
                      ),
                    ),
                  ),
                ),
        )
      ],
    );
  }
}
