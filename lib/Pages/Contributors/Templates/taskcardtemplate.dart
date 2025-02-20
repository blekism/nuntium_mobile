import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Contributors/createtaskpage.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskCardTemplate extends StatefulWidget {
  final String? taskPercent;
  final String? taskTitle;
  final String? status;
  final String? taskid;
  final String? taskType;
  final String? details;
  final bool isLoading;
  final String? assignedId;
  final String? pageType;

  const TaskCardTemplate({
    super.key,
    this.taskPercent,
    this.taskTitle,
    this.status,
    this.taskid,
    this.taskType,
    this.details,
    required this.isLoading,
    this.assignedId,
    this.pageType,
  });

  @override
  State<TaskCardTemplate> createState() => _TaskCardTemplate();
}

class _TaskCardTemplate extends State<TaskCardTemplate> {
  Future<List<Map<String, dynamic>>> fetchTasksById(String taskId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('tasks') // Change collection name if needed
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
        widget.pageType == 'eb'
            ? _showModal(context)
            : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CreateTaskPage(
                          taskId: widget.taskid,
                          details: widget.details,
                          title: widget.taskTitle,
                          taskType: widget.taskType,
                          assignedId: widget.assignedId,
                        )),
              );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * .90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: widget.status == "assigned"
              ? const Color(0xA6E4BD3D)
              : const Color(0xffB8CFED),
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
          children: [
            Container(
              width: MediaQuery.of(context).size.width * .10,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xff020B40),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Text(
                  widget.taskPercent ?? '0%', // Default to '0%' if null
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.taskType ?? 'Task Type', // Default text if null
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                          child: TaskCardTemplate(
                            taskid: widget.taskid,
                            taskTitle: widget.taskTitle,
                            taskType: tasks[index]['task_type'],
                            details: widget.details,
                            status: widget.status,
                            assignedId: tasks[index].id,
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
        );
      },
    );
  }
}
