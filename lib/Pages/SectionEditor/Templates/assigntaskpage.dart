import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssignTaskPage extends StatefulWidget {
  final String? section;

  const AssignTaskPage({super.key, this.section});

  @override
  State<AssignTaskPage> createState() => _AssignTaskPage();
}

class _AssignTaskPage extends State<AssignTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _taskDeadlineController = TextEditingController();
  final TextEditingController _taskDetailsController = TextEditingController();
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

  // List to hold task assignment containers
  List<Widget> _taskContainers = [];
  List<String> users = [];
  List<String> taskTitle = [];

  late Future<List<Map<String, String>>> _usersFuture;
  late Future<List<Map<String, String>>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = getUsers();
    _tasksFuture = getTasksTitle();
    _taskContainers.add(_buildTaskAssignmentContainer(0));
  }

  // Function to add a new task assignment container
  void _addTaskAssignmentContainer() {
    setState(() {
      _taskContainers
          .add(_buildTaskAssignmentContainer(_taskContainers.length));
    });
  }

  // Function to remove a task assignment container
  void _removeTaskAssignmentContainer(int index) {
    setState(() {
      _taskContainers.removeAt(index);
    });
  }

  //PARA SA PAG FETCH NG USERS FOR THE DROPDWOWN
  Future<List<Map<String, String>>> getUsers() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['contributor', 'section_writer'])
          .where('section', isEqualTo: widget.section)
          .get();

      List<Map<String, String>> fetchedUsers = querySnapshot.docs.map((doc) {
        return {
          'userId': doc.id, // Document ID
          'username': doc['username'] as String,
        };
      }).toList();

      print("Fetched users: $fetchedUsers");
      return fetchedUsers;
    } catch (e) {
      print("Error fetching users: $e");
      return [];
    }
  }

  Future<List<Map<String, String>>> getTasksTitle() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('tasks').get();

      List<Map<String, String>> fetchedTasks = querySnapshot.docs.map((doc) {
        return {
          'taskId': doc.id, // Document ID
          'title': doc['title'] as String,
        };
      }).toList();

      print("Fetched tasks: $fetchedTasks");
      return fetchedTasks;
    } catch (e) {
      print("Error fetching tasks: $e");
      return [];
    }
  }

  Future<void> assignTask() async {
    // final user = FirebaseAuth.instance.currentUser;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String? taskId = selectedTaskTitle;
        if (selectedMembers.isEmpty) {
          print("Error: No members selected");
          return;
        }
        String userId = selectedMembers[0]!;
        // String taskDetails = _taskDetailsController.text;
        // String taskDeadline = _taskDeadlineController.text;

        for (var member in selectedMembers) {
          print("Assigning to: $member");

          DocumentReference taskRef = await FirebaseFirestore.instance
              .collection('tasks')
              .doc(taskId)
              .collection('assigned_tasks')
              .add({
            'assignee_id': userId,
            'status': 'assigned',
            'submitted_at': FieldValue.serverTimestamp(),
            'task_id': taskId,
            'task_type': selectedTask,
            // 'details': taskDetails,
            // 'deadline': taskDeadline,
          });

          // Retrieve the newly added task and print it
          DocumentSnapshot newTask = await taskRef.get();
          print("Newly assigned task: ${newTask.data()}");
        }

        _formKey.currentState!.reset();
        _taskContainers = [_buildTaskAssignmentContainer(0)];
        // _taskDetailsController.clear();
        // _taskDeadlineController.clear();
        _selectedDate = null;
        selectedMembers = [''];

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task assigned successfully')),
        );
      } catch (e) {
        print("Error submitting task: $e");

        // Check if the widget is still mounted before using context
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Function to build the task assignment container
  Widget _buildTaskAssignmentContainer(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFff5f5f5),
                labelText: "Task",
                labelStyle: TextStyle(color: Colors.black),
              ),
              items: ['writing', 'photojourn', 'pubmat'].map((task) {
                return DropdownMenuItem(
                  value: task,
                  child: Text(task),
                );
              }).toList(),
              onChanged: (value) {
                selectedTask = value;
              },
              validator: (value) =>
                  value == null ? 'Please select a task' : null,
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, String>>>(
              future: _usersFuture, // Call getUsers() and wait for it
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("No users found.");
                }
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                    labelText: "Assign To",
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  items: snapshot.data!.map((user) {
                    return DropdownMenuItem(
                      value: user['userId'],
                      child: Text(user['username']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (index >= selectedMembers.length) {
                      selectedMembers.add(value);
                    } else {
                      selectedMembers[index] = value;
                    }
                  },
                  validator: (value) =>
                      value == null ? 'Please select a member' : null,
                );
              },
            ),
            const SizedBox(height: 5),
            if (index != 0)
              Align(
                alignment: Alignment.bottomRight,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeTaskAssignmentContainer(index),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? selectedTaskTitle;
  String? selectedTask;
  List<String?> selectedMembers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff020B40),
        title: const Text(
          'Assign Task',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: const Color(0xffF5F5F5),
              ),
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Assign Task ',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Task Title',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      //gawing droppydown
                      FutureBuilder<List<Map<String, String>>>(
                        future: _tasksFuture, // Call getUsers() and wait for it
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return Text("Error: ${snapshot.error}");
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text("No tasks found.");
                          }
                          return DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Color(0xFFF5F5F5),
                              labelText: "Task",
                              labelStyle: TextStyle(color: Colors.black),
                            ),
                            items: snapshot.data!.map((task) {
                              return DropdownMenuItem(
                                value: task['taskId'],
                                child: Text(task['title']!),
                              );
                            }).toList(),
                            onChanged: (value) {
                              selectedTaskTitle = value;
                            },
                            validator: (value) =>
                                value == null ? 'Please select a task' : null,
                          );
                        },
                      ),
                      // const SizedBox(height: 10),
                      // const Text(
                      //   'Task Details',
                      //   style: TextStyle(
                      //     color: Colors.black,
                      //     fontSize: 18,
                      //     fontWeight: FontWeight.w800,
                      //   ),
                      // ),
                      // const SizedBox(height: 10),
                      // TextFormField(
                      //   controller: _taskDeadlineController,
                      //   readOnly: true,
                      //   decoration: InputDecoration(
                      //     filled: true,
                      //     fillColor: const Color(0xFfffffff),
                      //     labelText: "Deadline",
                      //     border: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(10),
                      //     ),
                      //     focusedBorder: const OutlineInputBorder(
                      //       borderSide: BorderSide(
                      //         color: Color(0XFF020B40),
                      //       ),
                      //     ),
                      //     suffixIcon: IconButton(
                      //       icon: const Icon(Icons.calendar_today),
                      //       onPressed: _pickDate, // Opens the date picker
                      //     ),
                      //   ),
                      //   validator: (value) {
                      //     if (value == null || value.isEmpty) {
                      //       return "Please set a deadline";
                      //     }
                      //     return null;
                      //   },
                      // ),
                      // const SizedBox(height: 10),
                      // TextFormField(
                      //   controller: _taskDetailsController,
                      //   decoration: InputDecoration(
                      //     labelText: 'Details',
                      //     labelStyle: const TextStyle(
                      //       color: Color(0xFF020B40),
                      //       fontSize: 16,
                      //     ),
                      //     alignLabelWithHint: true,
                      //     filled: true,
                      //     fillColor: const Color(0xFfffffff),
                      //     border: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(10),
                      //     ),
                      //     focusedBorder: const OutlineInputBorder(
                      //       borderSide: BorderSide(
                      //         color: Color(0XFF020B40),
                      //       ),
                      //     ),
                      //   ),
                      //   keyboardType: TextInputType.multiline,
                      //   maxLines: 7,
                      //   style: const TextStyle(
                      //     color: Colors.black,
                      //   ),
                      //   validator: (value) {
                      //     if (value == null || value.isEmpty) {
                      //       return 'Please enter task details';
                      //     }
                      //     return null;
                      //   },
                      // ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Assign To:',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                color: Color(0xffD4AF37)),
                            onPressed:
                                _addTaskAssignmentContainer, // Adds a new container
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children:
                            _taskContainers, // Display all added task assignment containers
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: assignTask,
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
                                  'Assign Task',
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
          ),
        ),
      ),
    );
  }
}
