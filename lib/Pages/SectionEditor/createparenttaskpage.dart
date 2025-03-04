import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateParentTask extends StatefulWidget {
  final String? section;
  const CreateParentTask({super.key, this.section});

  @override
  State<CreateParentTask> createState() => _CreateParentTask();
}

class _CreateParentTask extends State<CreateParentTask> {
  final _formKey = GlobalKey<FormState>();
  final _taskTitleController = TextEditingController();
  final _taskDetailsController = TextEditingController();
  final _taskDeadlineController = TextEditingController();
  bool _isLoading = false;
  // For the deadline
  DateTime? _selectedDate;
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _taskDeadlineController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> createParentTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        DocumentReference taskRef =
            await FirebaseFirestore.instance.collection('tasks').add({
          'assigned_by': FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid),
          'created_at': FieldValue.serverTimestamp(),
          'title': _taskTitleController.text,
          'details': _taskDetailsController.text,
          'deadline': _selectedDate,
          'section': widget.section,
          'priority': selectedPriority,
          'isParent': 'Parent Task',
          'status': 'for approval',
        });

        DocumentSnapshot newTask = await taskRef.get();
        print("Newly assigned task: ${newTask.data()}");

        // Clear the form
        _taskTitleController.clear();
        _taskDetailsController.clear();
        _taskDeadlineController.clear();
        selectedPriority = null;

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New Task created successfully')),
        );
      } catch (e) {
        print("Error creating new task: $e");
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? taskTitle;
  String? taskDetails;
  String? taskDeadline;
  String? selectedPriority;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff020B40),
        title: const Text(
          'Create New Task',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: const Color(0xffF5F5F5),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.center,
                            child: Text(
                              'Create New Task ',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Task Title',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _taskTitleController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFfffffff),
                              labelText: 'Title',
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
                                return 'Please enter task title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Task Details',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _taskDeadlineController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFfffffff),
                              labelText: "Deadline",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0XFF020B40),
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: _pickDate, // Opens the date picker
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please set a deadline";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              filled: true,
                              fillColor: Color(0xFfffffff),
                              labelText: "Priority",
                              labelStyle: TextStyle(color: Colors.black),
                            ),
                            value: selectedPriority,
                            items: [
                              'Low Priority',
                              'Medium Priority',
                              'High Priority'
                            ].map((priority) {
                              return DropdownMenuItem(
                                value: priority,
                                child: Text(priority),
                              );
                            }).toList(),
                            onChanged: (value) {
                              selectedPriority = value;
                            },
                            validator: (value) =>
                                value == null ? 'Please set a priority' : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _taskDetailsController,
                            decoration: InputDecoration(
                              labelText: 'Details',
                              labelStyle: const TextStyle(
                                color: Color(0xFF020B40),
                                fontSize: 16,
                              ),
                              alignLabelWithHint: true,
                              filled: true,
                              fillColor: const Color(0xFfffffff),
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
                            maxLines: 7,
                            style: const TextStyle(
                              color: Colors.black,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter task details';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                    onPressed: createParentTask,
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
                                      'Create Task',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
