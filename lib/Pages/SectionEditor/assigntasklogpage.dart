import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:nuntium_mobile/Pages/SectionEditor/Templates/assigntaskpage.dart';

class AssignTaskLogPage extends StatefulWidget {
  const AssignTaskLogPage({super.key});

  @override
  State<AssignTaskLogPage> createState() => _AssignTaskLogPage();
}

class _AssignTaskLogPage extends State<AssignTaskLogPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Assigned Tasks',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            DottedBorder(
              color: const Color.fromARGB(255, 116, 116, 116),
              borderType: BorderType.RRect,
              radius: const Radius.circular(10),
              strokeWidth: 1,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AssignTaskPage(),
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
          ],
        ),
      ),
    );
  }
}
