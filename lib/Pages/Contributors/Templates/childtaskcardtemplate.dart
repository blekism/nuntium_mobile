import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Contributors/createtaskpage.dart';
import 'package:shimmer/shimmer.dart';

class ChildTaskCardTemplate extends StatefulWidget {
  final String? taskTitle;
  final String? status;
  final String? taskid;
  final String? taskType;
  final String? details;
  final bool isLoading;
  final String? assignedId;
  final String? pageType;
  final String? deadline;
  final String? isParent;
  final String? priority;

  const ChildTaskCardTemplate({
    super.key,
    this.taskTitle,
    this.status,
    this.taskid,
    this.taskType,
    this.details,
    required this.isLoading,
    this.assignedId,
    this.pageType,
    this.deadline,
    this.isParent,
    this.priority,
  });

  @override
  State<ChildTaskCardTemplate> createState() => _TaskCardTemplate();
}

class _TaskCardTemplate extends State<ChildTaskCardTemplate> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateTaskPage(
              taskId: widget.taskid,
              details: widget.details,
              title: widget.taskTitle,
              taskType: widget.taskType,
              assignedId: widget.assignedId,
            ),
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * .90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: switch (widget.status) {
              'assigned' => const Color(0xFF2A367C),
              'started' => const Color(0xFFD4AF37),
              'approved' => const Color(0xFF6A9C64),
              'for approval' => const Color.fromARGB(255, 255, 135, 135),
              _ => const Color(0xFFB8CFED), // Default color
            },
          ),
          color: switch (widget.status) {
            'assigned' => const Color(0xFFB8CFED),
            'started' => const Color(0x66D4AF37),
            'approved' => const Color(0xFFBAD8B6),
            'for approval' => const Color.fromARGB(255, 255, 135, 135),
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
                  'assigned' => const Color(0xFF2A367C),
                  'started' => const Color(0xFFD4AF37),
                  'approved' => const Color(0xFF6A9C64),
                  'for approval' => const Color.fromARGB(255, 255, 65, 65),
                  _ => const Color(0xFFB8CFED),
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
}
