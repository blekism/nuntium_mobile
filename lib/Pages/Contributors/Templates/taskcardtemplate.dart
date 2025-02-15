import 'package:flutter/material.dart';
import 'package:nuntium_mobile/Pages/Contributors/createtaskpage.dart';

class TaskCardTemplate extends StatefulWidget {
  final String? taskPercent;
  final String? taskTitle;
  final String? status;

  const TaskCardTemplate({
    super.key,
    this.taskPercent,
    this.taskTitle,
    this.status,
  });

  @override
  State<TaskCardTemplate> createState() => _TaskCardTemplate();
}

class _TaskCardTemplate extends State<TaskCardTemplate> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        width: MediaQuery.of(context).size.width * .90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: widget.status == "Assigned"
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
          child: _content(context),
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
            Text(
              widget.taskTitle ?? 'Task Title', // Default text if null
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateTaskPage()),
            );
          },
          child: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.black,
            size: 20,
          ),
        ),
      ],
    );
  }
}
