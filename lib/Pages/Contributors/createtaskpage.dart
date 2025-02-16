import 'package:flutter/material.dart';
import '../Contributors/Templates/timelinetabtemplate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateTaskPage extends StatefulWidget {
  final String? taskId;

  const CreateTaskPage({
    super.key,
    required this.taskId,
  });

  @override
  State<CreateTaskPage> createState() => _CreateTaskPage();
}

class _CreateTaskPage extends State<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;

  // Method for handling text input

  // Method for handling image selection
  Future<void> _pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage == null) return;

    setState(() {
      _selectedImage = File(pickedImage.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
      ),
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
                    'Title',
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
                    'Description',
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
                      labelText: 'Description',
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
                  ),
                  const SizedBox(height: 15),

                  // widget.taskType == 'text'
                  //     ? _writeTaskType()
                  //     : _buildImageInput(),
                  //dito mag pull ng data using the id then kunin yung task type
                  Text(
                    widget.taskId ?? 'Task Type',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        // Your action goes here
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF020B40),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10), // Rounded corners
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
                  ),

                  // dito yung button for timeline
                  const SizedBox(height: 15),

                  TimelineTab(),
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextFormField _writeTaskType() {
    return TextFormField(
      // controller: _fname,
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
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: _selectedImage != null
              ? Image.file(_selectedImage!,
                  width: 150, height: 150, fit: BoxFit.cover)
              : Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Text("Tap to select image")),
                ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _pickImage,
          child: const Text("Choose Image"),
        ),
      ],
    );
  }
}
