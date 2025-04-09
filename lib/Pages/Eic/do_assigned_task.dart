import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/Pages/Eic/assign_task_page.dart';
import 'package:nuntium_mobile/Pages/customappbar.dart';
import 'package:nuntium_mobile/firebase_functions.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class DoAssignedTaskPage extends ConsumerStatefulWidget {
  final String topicId, taskId, section, sectionId;

  const DoAssignedTaskPage({
    super.key,
    required this.topicId,
    required this.taskId,
    required this.section,
    required this.sectionId,
  });

  @override
  ConsumerState<DoAssignedTaskPage> createState() => _DoAssignedTaskPageState();
}

class _DoAssignedTaskPageState extends ConsumerState<DoAssignedTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _headlineController = TextEditingController();
  final firebaseFunctions = FirebaseFunctions();

  @override
  Widget build(BuildContext context) {
    final assignedTaskView =
        ref.watch(taskWrittenProvider((widget.topicId, widget.taskId)));
    final canUserEdit =
        firebaseFunctions.canUserEdit(firebaseFunctions.auth.currentUser!.uid);

    return Scaffold(
      appBar: const CustomAppBar(
        appbarTitle: 'Create Your Content',
        hasNavigated: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                assignedTaskView.when(
                  data: (assignedTask) {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Task Title: ',
                                  style: TextStyle(
                                    color: Color(0xFF020B40),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            FutureBuilder<bool>(
                              future: canUserEdit,
                              builder: (BuildContext context,
                                  AsyncSnapshot<bool> snapshot) {
                                if (snapshot.hasData) {
                                  final userCanEdit =
                                      snapshot.data!; // Safely unwrap the bool

                                  return userCanEdit
                                      ? Align(
                                          alignment: Alignment.topRight,
                                          child: IconButton(
                                            onPressed: () {
                                              print(
                                                  'editing this ${assignedTask.deadline}');
                                              print(
                                                  'editing this ${assignedTask.assignee}');
                                              print(
                                                  'editing this ${assignedTask.title}');
                                              print(
                                                  'editing this ${assignedTask.tasktype}');
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      AssignTaskPage(
                                                    isEditing: true,
                                                    deadline:
                                                        assignedTask.deadline,
                                                    member:
                                                        assignedTask.assignee,
                                                    taskname:
                                                        assignedTask.title,
                                                    tasktype:
                                                        assignedTask.tasktype,
                                                    sectionId: widget.sectionId,
                                                    topicId: widget.topicId,
                                                    taskId: assignedTask.taskId,
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.edit),
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                } else if (snapshot.hasError) {
                                  return Text(
                                      'Error: ${snapshot.error}'); // Handle error appropriately
                                } else {
                                  return const CircularProgressIndicator(); // Show loading indicator
                                }
                              },
                            )
                          ],
                        ),
                        const SizedBox(height: 7),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            assignedTask.title,
                            style: const TextStyle(
                              color: Color(0xFF020B40),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            ' ${widget.section} | ${assignedTask.deadline} ',
                            style: const TextStyle(
                              color: Color(0xFF505050),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            ' Created by: ${assignedTask.assigner} | ${assignedTask.priority}',
                            style: const TextStyle(
                              color: Color(0xFF505050),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Task Details: ',
                            style: TextStyle(
                              color: Color(0xFF020B40),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            assignedTask.details,
                            style: const TextStyle(
                              color: Color(0xFF020B40),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Headline',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: _headlineController,
                          keyboardType: TextInputType.multiline,
                          maxLines: 2,
                          cursorColor: const Color(0XFF020B40),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0XFFF5F5F5),
                            labelText: 'Headline',
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
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 7),
                        TextFormField(
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
                              return 'Please enter the topic content';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 60,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    showDialog<bool>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text(
                                              'Confirm Task Submission'),
                                          content: const Text(
                                              'Are you sure you want to submit this task?'),
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
                                                print(
                                                    'pinindot mo pre kaya nakapagsubmit ka');
                                              },
                                              child: const Text('Assign'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
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
                                    'Submit!',
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
                                  showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Confirm Discard'),
                                        content: const Text(
                                            'Are you sure you want to discard this task? Any unsaved changes will be lost.'),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text('Discard'),
                                          ),
                                        ],
                                      );
                                    },
                                  ).then((value) {
                                    if (value == true) {
                                      // Handle discard logic here, e.g., navigate back
                                      Navigator.pop(context);
                                    }
                                  });
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
                                    'Discard',
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
                    );
                  },
                  error: (error, stack) => Center(child: Text('Error: $error')),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
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
