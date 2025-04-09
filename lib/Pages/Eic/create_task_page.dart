import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class CreateTaskPage extends ConsumerStatefulWidget {
  //params for creation after this comment
  final String? sectionID;
  final String? sectionName;
  //params for update/edit after this comment
  final String? topicId, deadline, details, priority, title;
  final bool isEditing;

  const CreateTaskPage({
    super.key,
    this.sectionID,
    this.sectionName,
    this.topicId,
    this.deadline,
    this.details,
    this.priority,
    this.title,
    this.isEditing = false,
  });

  @override
  ConsumerState<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends ConsumerState<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priorityController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  String? _selectedSectionID;
  String? _selectedPriority;
  bool _didInitDropdown = false;
  bool isUpdateSuccess = false;

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
    print('creating topic for: ${widget.sectionID} and ${widget.sectionName}');
    if (widget.sectionID != null) {
      _sectionController.text = widget.sectionName!;
    }

    if (widget.isEditing == true) {
      print('editing ka ng topic bruh');
      _titleController.text = widget.title!;
      _detailController.text = widget.details!;
      _deadlineController.text = widget.deadline!;
      _selectedPriority = widget.priority!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = ref.watch(sectionProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        appbarTitle: 'Create A New Topic',
        hasNavigated: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Topic Details',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0XFF020B40),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 7),
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
                  const SizedBox(height: 7),
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Priority',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedPriority = newValue!;
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0XFFF5F5F5),
                      labelText: 'Priority',
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
                      'High Priority',
                      'Medium Priority',
                      'Low Priority',
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
                        return 'Please select Topic priority';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 7),
                  widget.isEditing == false
                      ? const Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Section',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  const SizedBox(height: 7),
                  widget.isEditing == false
                      ? sections.when(
                          data: (sections) {
                            final docs = sections.docs;

                            // Set initial value once, only when data is loaded
                            if (!_didInitDropdown && widget.sectionID != null) {
                              final exists =
                                  docs.any((doc) => doc.id == widget.sectionID);
                              if (exists) {
                                _selectedSectionID = widget.sectionID;
                              }
                              _didInitDropdown = true;
                            }

                            return DropdownButtonFormField(
                              value: _selectedSectionID,
                              items: docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final name = data['sectionType'] ?? 'unknown';
                                return DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text(name),
                                );
                              }).toList(),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0XFFF5F5F5),
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
                              onChanged: (value) {
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
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stackTrace) => Text('Error: $error'),
                        )
                      : const SizedBox.shrink(),
                  const SizedBox(height: 7),
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Details',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  TextFormField(
                    controller: _detailController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 8,
                    cursorColor: const Color(0XFF020B40),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0XFFF5F5F5),
                      labelText: 'Details',
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
                        return 'Please enter the topic details';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  widget.isEditing == false
                      ? SizedBox(
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title:
                                          const Text('Confirm Topic Creation'),
                                      content: const Text(
                                          'Are you sure you want to create this topic?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () => Navigator.of(context)
                                              .pop(false), // No
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.of(context)
                                                .pop(true); // Yes
                                          },
                                          child: const Text('Create'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirm == true) {
                                  try {
                                    await firebaseFunctions.createTopic(
                                      FirebaseAuth.instance.currentUser!.uid,
                                      _titleController.text,
                                      _deadlineController.text,
                                      _priorityController.text,
                                      _detailController.text,
                                      _selectedSectionID,
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Topic created successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (error) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to create topic: $error'),
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
                                'Create A Topic!',
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
                              if (_formKey.currentState?.validate() ?? false) {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title:
                                          const Text('Confirm Topic Updates'),
                                      content: const Text(
                                          'Are you sure you want to update this topic?'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop(true);
                                          },
                                          child: const Text('Update'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirm == true) {
                                  try {
                                    await firebaseFunctions.updateTopic(
                                      widget.topicId!,
                                      _titleController.text,
                                      _detailController.text,
                                      _deadlineController.text,
                                      _selectedPriority,
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Topic updated successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (error) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to update topic: $error'),
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
                                'Update This Topic!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
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
}
