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
  final String? status;
  final String? section;

  const ParentTaskCardTemplate({
    super.key,
    required this.isLoading,
    this.taskTitle,
    this.taskDeadline,
    this.taskid,
    this.details,
    this.status,
    this.section,
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
          color: const Color(0xffD9D9D9),
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
            const SizedBox(height: 5),
            Container(
              padding:
                  const EdgeInsets.only(top: 5, bottom: 5, right: 10, left: 10),
              decoration: BoxDecoration(
                color: const Color(0xffA31D1D),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                widget.taskDeadline ?? 'Dealine', // Default text if null
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                          builder: (context) =>
                              AssignTaskPage(section: widget.section),
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
