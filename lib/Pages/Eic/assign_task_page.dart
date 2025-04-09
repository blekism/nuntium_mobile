import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class AssignTaskPage extends ConsumerStatefulWidget {
  final String topicId;
  final String? section;
  final String sectionId;
  final bool isEditing;
  final String? taskname, deadline, tasktype, member, taskId;

  const AssignTaskPage({
    super.key,
    required this.topicId,
    this.section,
    required this.sectionId,
    this.isEditing = false,
    this.tasktype,
    this.taskname,
    this.deadline,
    this.member,
    this.taskId,
  });

  @override
  ConsumerState<AssignTaskPage> createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends ConsumerState<AssignTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _taskTypeController = TextEditingController();
  bool _didInitDropdown = false;
  String? _selectedMemberId;
  String? _selectedTaskType;

  DateTime? _selectedDateTime;
  final firebaseFunctions = FirebaseFunctions();

  Future<void> _pickDateTime() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime;

      if (mounted) {
        pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
      } else {
        return;
      }

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime!.hour,
            pickedTime.minute,
          );
          _deadlineController.text =
              "${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year} ${pickedTime.format(context)}";
          // print(_birthDateController.text);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEditing == true) {
      print('you are editing');
      _titleController.text = widget.taskname!;
      _deadlineController.text = widget.deadline!;
      _selectedTaskType = widget.tasktype!;
      _selectedMemberId = widget.member!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberList = ref.watch(memberListProvider(widget.sectionId));

    return Scaffold(
      appBar: const CustomAppBar(
        hasNavigated: false,
        appbarTitle: 'Assign A Task',
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Task Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0XFF020B40),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Title',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  TextFormField(
                    controller: _titleController,
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
                        return 'Please enter the task title';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Deadline',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  TextFormField(
                    controller: _deadlineController,
                    readOnly: true,
                    cursorColor: const Color(0XFF020B40),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0XFFF5F5F5),
                      labelText: 'Deadline',
                      labelStyle: const TextStyle(
                        color: Color(0xFF020B40),
                        fontSize: 12,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 5.0),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _pickDateTime,
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
                        return 'Please enter the deadline';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Deadline',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  memberList.when(
                    data: (memberList) {
                      if (memberList.isEmpty) {
                        return const Center(
                          child: Text('No members found'),
                        );
                      }
                      if (!_didInitDropdown) {
                        _didInitDropdown = true;
                      }

                      return DropdownButtonFormField(
                        value: _selectedMemberId,
                        items: memberList.map((member) {
                          return DropdownMenuItem<String>(
                            value: member.id,
                            child: Text(member.username),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0XFFF5F5F5),
                          labelText: 'Member',
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
                        onChanged: (value) {
                          setState(() {
                            _selectedMemberId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a Member';
                          }
                          return null;
                        },
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stackTrace) => Text('Error: $error'),
                  ),
                  const SizedBox(height: 7),
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Task Type',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  DropdownButtonFormField<String>(
                    value: _selectedTaskType,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedTaskType =
                            newValue!; // Update _selectedTaskType
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0XFFF5F5F5),
                      labelText: 'Task Type',
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
                    style: const TextStyle(
                      color: Colors.white, // Text color white
                    ),
                    items: <String>[
                      'Writing',
                      'Pubmat',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    }).toList(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a Task Type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      widget.isEditing == false
                          ? SizedBox(
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
                                              'Confirm Task Assignment'),
                                          content: const Text(
                                              'Are you sure you want to assign this task?'),
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
                                              child: const Text('Assign'),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirm == true) {
                                      try {
                                        await firebaseFunctions.createTask(
                                          widget.topicId,
                                          _deadlineController.text,
                                          _taskTypeController.text,
                                          _titleController.text,
                                          _selectedMemberId,
                                        );

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Task Created successfully!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (error) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Failed to Create task: $error'),
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
                                    'Assign Task!',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 60,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title:
                                              const Text('Confirm Task Update'),
                                          content: const Text(
                                              'Are you sure you want to update this task?'),
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
                                              child: const Text('Update'),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirm == true) {
                                      try {
                                        await firebaseFunctions.updateContent(
                                          widget.topicId,
                                          widget.taskId,
                                          _titleController.text,
                                          _deadlineController.text,
                                          _selectedTaskType,
                                          _selectedMemberId,
                                        );

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Task updated successfully!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (error) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Failed to update Task: $error'),
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
                                    'Update Task!',
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
                            if (_formKey.currentState?.validate() ?? false) {
                              print('cancelled pre');
                            }
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
                              'Cancel',
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
