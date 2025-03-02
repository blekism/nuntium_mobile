import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nuntium_mobile/Pages/Contributors/Templates/childtaskcardtemplate.dart';

class TaskCardTemplate extends StatefulWidget {
  final String? taskTitle;
  final String? status;
  final String? taskid;
  final String? taskType;
  final String? details;
  final bool isLoading;
  final String? assignedId;
  final String? deadline;
  final String? isParent;
  final String? priority;

  const TaskCardTemplate({
    super.key,
    this.taskTitle,
    this.status,
    this.taskid,
    this.taskType,
    this.details,
    required this.isLoading,
    this.assignedId,
    this.deadline,
    this.isParent,
    this.priority,
  });

  @override
  State<TaskCardTemplate> createState() => _TaskCardTemplate();
}

class _TaskCardTemplate extends State<TaskCardTemplate> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showModal(context);
      },
      child: Container(
        width: MediaQuery.of(context).size.width * .90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: switch (widget.status) {
              'created' => const Color(0xFF505050),
              'waiting' => const Color(0xFF2A367C),
              'started' => const Color(0xFFD4AF37),
              'in_progress' => const Color(0xFFD4AF37),
              'ready_post' => const Color(0xFF6A9C64),
              _ => const Color(0xFFB8CFED), // Default color
            },
          ),
          color: switch (widget.status) {
            'created' => const Color(0xFFE4E4E4),
            'waiting' => const Color(0xFFB8CFED),
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
                          child: ChildTaskCardTemplate(
                            taskid: widget.taskid,
                            taskTitle: widget.taskTitle,
                            taskType: tasks[index]['task_type'],
                            details: widget.details,
                            status: tasks[index]['status'],
                            assignedId: tasks[index].id,
                            isLoading: false,
                            isParent: tasks[index]['isParent'],
                            // deadline: tasks[index]['deadline'],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
