import 'package:flutter/material.dart';

class AssignTaskPage extends StatefulWidget {
  const AssignTaskPage({super.key});

  @override
  State<AssignTaskPage> createState() => _AssignTaskPage();
}

class _AssignTaskPage extends State<AssignTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _taskDeadlineController = TextEditingController();
  final TextEditingController _taskDetailsController = TextEditingController();

  // For the birthdate
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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

  @override
  void initState() {
    super.initState();
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

  bool _isLoading = false;

  // Function to build the task assignment container
  Widget _buildTaskAssignmentContainer(int index) {
    String? selectedTask;
    String? selectedMember;

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
              items: ['Writing', 'Photojourn'].map((task) {
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
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFff5f5f5),
                labelText: "Assign To",
                labelStyle: TextStyle(color: Colors.black),
              ),
              items: [
                'Member 1',
                'Member 2',
                'Member 3',
                'Member 4',
                'Member 5'
              ].map((member) {
                return DropdownMenuItem(
                  value: member,
                  child: Text(member),
                );
              }).toList(),
              onChanged: (value) {
                selectedMember = value;
              },
              validator: (value) =>
                  value == null ? 'Please select a member' : null,
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
      body: SingleChildScrollView(
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
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _taskTitleController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Title',
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
                    TextFormField(
                      controller: _taskDetailsController,
                      readOnly: true,
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
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      // if (_formKey.currentState!.validate()) {
                                      //   registerInfo(
                                      //     _nameController.text,
                                      //     _courseController.text,
                                      //     _sectionController.text,
                                      //     _bdayController.text,
                                      //     _selectedSex ?? '',
                                      //     _emailController.text,
                                      //     _cnumController.text,
                                      //   );
                                      // }
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
}
