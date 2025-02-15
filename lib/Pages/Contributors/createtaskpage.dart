import 'package:flutter/material.dart';
import '../Contributors/Templates/timelinetabtemplate.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPage();
}

class _CreateTaskPage extends State<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
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
                  TextFormField(
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
                        'Submit for Revision',
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
}
