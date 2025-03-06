import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssignTaskPage extends StatefulWidget {
  final String? section;
  final String? taskid;

  const AssignTaskPage({super.key, this.section, this.taskid});

  @override
  State<AssignTaskPage> createState() => _AssignTaskPage();
}

// TODO: implement datetime picker

class _AssignTaskPage extends State<AssignTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _taskDeadlineController = TextEditingController();
  final TextEditingController _taskDetailsController = TextEditingController();
  final TextEditingController _taskTitleController = TextEditingController();
  bool _isLoading = false;

  // List to hold task assignment containers
  // List<Widget> _taskContainers = [];
  List<String> users = [];
  List<String> taskTitle = [];

  late Future<List<Map<String, String>>> _usersFuture;
  late Future<List<Map<String, String>>> _tasksFuture;

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

  @override
  void initState() {
    super.initState();
    _usersFuture = getUsers();
    _tasksFuture = getTasksTitle();
    // _taskContainers.add(_buildTaskAssignmentContainer(0));
  }

  // Function to add a new task assignment container
  // void _addTaskAssignmentContainer() {
  //   setState(() {
  //     _taskContainers
  //         .add(_buildTaskAssignmentContainer(_taskContainers.length));
  //   });
  // }

  // // Function to remove a task assignment container
  // void _removeTaskAssignmentContainer(int index) {
  //   setState(() {
  //     _taskContainers.removeAt(index);
  //   });
  // }

  //PARA SA PAG FETCH NG USERS FOR THE DROPDWOWN
  Future<List<Map<String, String>>> getUsers() async {
    try {
      QuerySnapshot querySnapshot = widget.section != 'all'
          ? await FirebaseFirestore.instance
              .collection('users')
              .where('role', whereIn: ['contributor', 'section_writer'])
              .where('section', isEqualTo: widget.section)
              .get()
          : await FirebaseFirestore.instance
              .collection('users')
              .where('role', isNotEqualTo: 'reader')
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
      if (widget.taskid == null || widget.taskid!.isEmpty) {
        debugPrint("Error: Task ID is null or empty");
        return [];
      }

      print("Fetching task with ID: ${widget.taskid}"); // Debugging

      DocumentSnapshot taskSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskid)
          .get();

      if (taskSnapshot.exists) {
        String taskTitle = taskSnapshot.get('title') as String? ?? '';
        _taskTitleController.text = taskTitle;
        print("Task Found: $taskTitle"); // Debugging
        return [
          {
            'taskId': taskSnapshot.id,
            'title': taskTitle,
          }
        ];
      } else {
        debugPrint("Task not found with ID: ${widget.taskid}");
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching task: $e");
      return [];
    }
  }

  Future<void> conditionalUpdate(String documentId) async {
    try {
      final DocumentReference docRef =
          FirebaseFirestore.instance.collection('tasks').doc(documentId);

      // Get the current document data.
      final DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final Map<String, dynamic> data =
            docSnapshot.data() as Map<String, dynamic>;
        final int totalSubtasks =
            data['total_subtasks'] ?? 0; // Handle null cases
        final int completedSubtasks =
            data['completed_subtasks'] ?? 0; // Handle null cases

        if (totalSubtasks == completedSubtasks) {
          // Condition met: Update the field.
          await docRef.update({'status': 'ready_post'});
          print('Document updated successfully.');
        } else {
          await docRef.update({'status': 'assigned'});
          print('Condition not met. Document not updated.');
        }
      } else {
        print('Document does not exist.');
      }
    } catch (e) {
      print('Error performing conditional update: $e');
    }
  }

  Future<void> assignTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      try {
        if (selectedMembers == null) {
          print("Error: No members selected");
          return;
        }

        var member = selectedMembers;
        print("Assigning to: $member");
        print("Task ID: ${widget.taskid}");

        DocumentReference taskRef = await FirebaseFirestore.instance
            .collection('tasks')
            .doc(widget.taskid)
            .collection('assigned_tasks')
            .add({
          'assignee_id': member,
          'status': 'assigned',
          'created_at': FieldValue.serverTimestamp(),
          'task_id': widget.taskid,
          'task_type': selectedTask,
          'isParent': 'Child Task',
          'priority': selectedPriority,
          'deadline': _selectedDate,
        });

        await FirebaseFirestore.instance
            .collection('tasks')
            .doc(widget.taskid)
            .update({
          'total_subtasks': FieldValue.increment(1),
        });

        await conditionalUpdate(widget.taskid!);

        DocumentSnapshot newTask = await taskRef.get();
        print("Newly assigned task: ${newTask.data()}");

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task assigned successfully')),
        );
      } catch (e) {
        print("Error submitting task: $e");

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        // Only reset fields *after* submission is done
        if (mounted) {
          setState(() {
            _isLoading = false;
            _taskDeadlineController.clear();
            selectedMembers = null;
            selectedPriority = null;
            selectedTask = null;
          });
        }
      }
    }
  }

  String? selectedTaskTitle;
  String? selectedTask;
  String? selectedMembers;
  String? selectedPriority;

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
      body: FutureBuilder(
          future: Future.wait([
            _usersFuture,
          ]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else {
              return Center(
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
                              //TODO: i love boger baby hihi
                              TextFormField(
                                controller: _taskTitleController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Task Title',
                                  labelStyle: const TextStyle(
                                    // color: Color(0xFF020B40),
                                    fontSize: 16,
                                  ),
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
                              DropdownButtonFormField<String>(
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  filled: true,
                                  fillColor: Color(0xFfffffff),
                                  labelText: "Priority",
                                  // labelStyle: TextStyle(color: Colors.black),
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
                                validator: (value) => value == null
                                    ? 'Please set a priority'
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _taskDeadlineController,
                                readOnly: true,
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
                                    onPressed:
                                        _pickDate, // Opens the date picker
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
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Assign To:',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  // IconButton(
                                  //   icon: const Icon(Icons.add_circle_outline,
                                  //       color: Color(0xffD4AF37)),
                                  //   onPressed:
                                  //       _addTaskAssignmentContainer, // Adds a new container
                                  // ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Column(
                              //   children:
                              //       _taskContainers, // Display all added task assignment containers
                              // ),
                              DropdownButtonFormField<String>(
                                value: selectedTask,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  filled: true,
                                  fillColor: Color(0xFffFfFfF),
                                  labelText: "Task",
                                  // labelStyle: TextStyle(color: Colors.black),
                                ),
                                items: ['writing', 'photojourn', 'pubmat']
                                    .map((task) {
                                  return DropdownMenuItem(
                                    value: task,
                                    child: Text(task),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  selectedTask = value;
                                },
                                validator: (value) => value == null
                                    ? 'Please select a task'
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              FutureBuilder<List<Map<String, String>>>(
                                future:
                                    _usersFuture, // Call getUsers() and wait for it
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  }
                                  if (snapshot.hasError) {
                                    return Text("Error: ${snapshot.error}");
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const Text("No users found.");
                                  }
                                  return DropdownButtonFormField<String>(
                                    value: selectedMembers,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                      filled: true,
                                      fillColor: Color(0xFFFFFFFF),
                                      labelText: "Assign To",
                                      // labelStyle: TextStyle(color: Colors.black),
                                    ),
                                    items: snapshot.data!.map((user) {
                                      return DropdownMenuItem(
                                        value: user['userId'],
                                        child: Text(user['username']!),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      selectedMembers = value;
                                    },
                                    validator: (value) => value == null
                                        ? 'Please select a member'
                                        : null,
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _isLoading
                                    ? const CircularProgressIndicator()
                                    : ElevatedButton(
                                        onPressed: assignTask,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF020B40),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
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
              );
            }
          }),
    );
  }
}
