import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:nuntium_mobile/Pages/SectionEditor/Templates/assigntaskpage.dart';
import 'package:nuntium_mobile/Pages/Contributors/Templates/taskcardtemplate.dart';

class ParentTaskCardTemplate extends StatefulWidget {
  final bool isLoading;
  final String? taskTitle;
  final String? taskDeadline;
  final String? taskid;
  final String? details;
  final String? deadline;
  final String? status;
  final String? section;
  final String? isParent;
  final String? priority;

  const ParentTaskCardTemplate({
    super.key,
    required this.isLoading,
    this.taskTitle,
    this.taskDeadline,
    this.taskid,
    this.details,
    this.deadline,
    this.status,
    this.section,
    this.isParent,
    this.priority,
  });

  @override
  State<ParentTaskCardTemplate> createState() => _ParentTaskCardTemplateState();
}

class _ParentTaskCardTemplateState extends State<ParentTaskCardTemplate> {
  Future<List<Map<String, dynamic>>> fetchTasksById(String taskId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskid)
          .collection('assigned_tasks')
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error fetching tasks: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print("Clicked Task ID: ${widget.taskid}");
        _showModal(context);
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
              'in_progress' => const Color(0xFFD4AF37),
              'ready_post' => const Color(0xFF6A9C64),
              _ => const Color(0xFFB8CFED), // Default color
            },
          ),
          color: switch (widget.status) {
            'created' => const Color(0xFFE4E4E4),
            'assigned' => const Color(0xFFB8CFED),
            'started' => const Color(0x66D4AF37),
            'in_progress' => const Color(0x66D4AF37),
            'ready_post' => const Color(0xFFBAD8B6),
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
                  'waiting' => const Color(0xFF2A367C),
                  'started' => const Color(0xFFD4AF37),
                  'in_progress' => const Color(0xFFD4AF37),
                  'ready_post' => const Color(0xFF6A9C64),
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
                  widget.deadline ?? 'Task deadline', // Default text if null
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
                  width: MediaQuery.of(context).size.width * .25,
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: FractionallySizedBox(
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
                DottedBorder(
                  color: const Color.fromARGB(255, 116, 116, 116),
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(10),
                  strokeWidth: 1,
                  child: GestureDetector(
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
                const SizedBox(height: 10),
                const Text(
                  'Assigned Tasks',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('tasks')
                        .doc(widget.taskid)
                        .collection('assigned_tasks')
                        .snapshots(),
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

                      return ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(
                                left: 16.0, right: 16.0, bottom: 16),
                            child: TaskCardTemplate(
                              taskid: widget.taskid,
                              taskTitle: widget.taskTitle,
                              taskType: tasks[index]['task_type'],
                              details: widget.details,
                              status: widget.status,
                              assignedId: tasks[index].id,
                              isParent: widget.isParent,
                              priority: widget.priority,
                              deadline: widget.taskDeadline,
                              isLoading: false,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
