import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nuntium_mobile/Pages/Contributors/Templates/childtaskcardtemplate.dart';
import 'package:nuntium_mobile/Pages/Committee/taskcontentpage.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:nuntium_mobile/Pages/SectionEditor/Templates/assigntaskpage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskCardTemplate extends StatefulWidget {
  final String? taskTitle;
  final String? status;
  final String? taskid;
  final String? taskType;
  final String? details;
  final bool isLoading;
  final String? deadline;
  final String? isParent;
  final String? priority;
  final String? section;
  final int? completedTask;
  final int? totalTask;

  const TaskCardTemplate({
    super.key,
    this.taskTitle,
    this.status,
    this.taskid,
    this.taskType,
    this.details,
    required this.isLoading,
    this.deadline,
    this.isParent,
    this.priority,
    this.section,
    this.completedTask,
    this.totalTask,
  });

  @override
  State<TaskCardTemplate> createState() => _TaskCardTemplate();
}

class _TaskCardTemplate extends State<TaskCardTemplate> {
  bool isManagement = false;
  late Stream<QuerySnapshot> assignedTasksStream;

  @override
  void initState() {
    super.initState();
    _checkUser();

    assignedTasksStream = FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskid)
        .collection('assigned_tasks')
        .snapshots();
  }

  Future<void> _readyPostTask() {
    print('Task is ready for posting pasok committee');
    return FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskid)
        .update({'status': 'ready_post'});
  }

  Future<void> _checkUser() async {
    var user = FirebaseAuth.instance.currentUser;
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (userDoc['role'] == 'eic') {
      setState(() {
        isManagement = true;
      });
    }
  }

  Future<void> _approveTask() async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskid)
        .update({'status': 'created'});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.status == 'ready_post') {
          print('Task ID being passed: ${widget.taskid}');
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TaskContentPage(taskid: widget.taskid)),
          );
        } else {
          _showModal(context);
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width * .90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: switch (widget.status) {
              'created' => const Color(0xFF505050),
              'assigned' => const Color(0xFF2A367C),
              'started' => const Color(0xFFD4AF37),
              'in_progress' => const Color.fromARGB(255, 250, 150, 114),
              'ready_post' => const Color(0xFF6A9C64),
              'for approval' => const Color.fromARGB(255, 255, 135, 135),
              'pendingAPR' => const Color(0XFFE8D9F3),
              'pendingPST' => const Color(0XFFFFD19C),
              _ => const Color(0xFFB8CFED), // Default color
            },
          ),
          color: switch (widget.status) {
            'created' => const Color(0xFFE4E4E4),
            'assigned' => const Color(0xFFB8CFED),
            'started' => const Color(0x66D4AF37),
            'in_progress' => const Color.fromARGB(255, 250, 150, 114),
            'ready_post' => const Color(0xFFBAD8B6),
            'for approval' => const Color.fromARGB(255, 255, 135, 135),
            'pendingAPR' => const Color(0XFFE8D9F3),
            'pendingPST' => const Color(0XFFFFD19C),
            _ => const Color(0xFFB8CFED), // Default color
          },
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: widget.isLoading ? _shimmerContent() : _content(context),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Container(
                width: MediaQuery.of(context).size.width * .10,
                height: MediaQuery.of(context).size.height * .05,
                color: switch (widget.status) {
                  'created' => const Color(0xFF505050),
                  'assigned' => const Color(0xFF2A367C),
                  'started' => const Color(0xFFD4AF37),
                  'in_progress' => const Color.fromARGB(255, 255, 128, 81),
                  'ready_post' => const Color(0xFF6A9C64),
                  'for approval' => const Color.fromARGB(255, 255, 65, 65),
                  'pendingAPR' => const Color(0XFF735ECA),
                  'pendingPST' => const Color(0XFFE78F2F),
                  _ => const Color(0xFFB8CFED), // Default color
                },
                child: const Center(
                  child: Icon(
                    Icons.newspaper,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.taskTitle ?? 'Task Title', // Default text if null
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '0/10 tasks started', // Default text if null
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  widget.deadline ??
                      'Task deadline test', // Default text if null
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * .25,
                      decoration: ShapeDecoration(
                        color: const Color(0XFF020B40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          widget.isParent ?? 'Parent Task',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: MediaQuery.of(context).size.width * .25,
                      decoration: ShapeDecoration(
                        color: const Color(0XFFDA6136),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          widget.status ?? 'Waiting',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  width: MediaQuery.of(context).size.width * .30,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFA31D1D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      widget.priority ?? 'High Priority',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.black,
          size: 20,
        ),
      ],
    );
  }

  Widget _shimmerContent() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * .10,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(width: 15),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 100,
                    height: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white,
            size: 20,
          ),
        ],
      ),
    );
  }

  void _showModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: DottedBorder(
                  color: const Color.fromARGB(255, 116, 116, 116),
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(10),
                  strokeWidth: 1,
                  child: widget.status == 'pendingAPR'
                      ? Center(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.taskTitle ?? 'No Title',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2A367C),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.details ?? 'No details provided',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Text(
                                      'Deadline:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.deadline ?? 'Not set',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text(
                                      'Priority:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.priority ?? 'Not set',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text(
                                      'Section:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.section ?? 'Not set',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text(
                                      'Status:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.status ?? 'Not set',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                isManagement
                                    ? ElevatedButton(
                                        onPressed: () {
                                          _approveTask();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF735ECA),
                                        ),
                                        child: const Text(
                                          'Approve Task',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () async {
                            print("Fetching user section...");

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AssignTaskPage(
                                  section: widget.section,
                                  taskid: widget.taskid,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xfff5f5f5),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Assign New Task',
                                      style: TextStyle(
                                        color: Colors.blueGrey,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Icon(Icons.add, color: Colors.blueGrey),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const Text(
                'Assign New Tasks',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: assignedTasksStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const SizedBox(
                        height: 300,
                        child: Center(child: Text("Error loading tasks")),
                      );
                    } else if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return const SizedBox(
                        height: 300,
                        child: Center(child: Text("No tasks assigned")),
                      );
                    }

                    var tasks = snapshot.data!.docs;
                    print('task deadline is: ${widget.deadline}');

                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        print('assigned task id is: ${tasks[index].id}');
                        return Padding(
                          padding: const EdgeInsets.only(
                              left: 16.0, right: 16.0, bottom: 16),
                          child: ChildTaskCardTemplate(
                            taskid: widget.taskid,
                            status: tasks[index]['status'],
                            assignedId: tasks[index]['assignee_id'],
                            isLoading: false,
                            isParent: tasks[index]['isParent'],
                            taskType: tasks[index]['task_type'],
                            priority: tasks[index]['priority'],
                            childTaskId: tasks[index].id,
                            // deadline: widget.deadline,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              widget.completedTask == widget.totalTask
                  ? ElevatedButton(
                      onPressed: () {
                        _readyPostTask();
                        print('Task completed');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF735ECA),
                      ),
                      child: const Text(
                        'Mark Task as Completed',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        );
      },
    );
  }
}
