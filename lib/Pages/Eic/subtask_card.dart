import 'package:flutter/material.dart';

class SubtaskCard extends StatelessWidget {
  final String imageurl, id, title, section, type, deadline, priority;

  const SubtaskCard({
    super.key,
    required this.id,
    required this.title,
    required this.imageurl,
    required this.section,
    required this.type,
    required this.deadline,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        width: MediaQuery.of(context).size.width * .85,
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: const Color(0XFFB8CFED),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$section | $type',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 25, // Adjust radius as needed
                ),
              ],
            ),
            const SizedBox(height: 16), // Add spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (() {
                      switch (priority) {
                        case 'High Priority':
                          return const Color(0xFFFFE0E0); // light red
                        case 'Medium Priority':
                          return const Color(0xFFFFF8E0); // light yellow
                        case 'Low Priority':
                          return const Color(0xFFE0FFE0); // light green
                        default:
                          return const Color(0xFFDDE4FB); // default blue
                      }
                    })(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    priority,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA3A3A3),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        offset: const Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.access_time_filled_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        deadline,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  backgroundImage: NetworkImage(
                    imageurl,
                  ),
                  radius: 20, // Adjust radius as needed
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
