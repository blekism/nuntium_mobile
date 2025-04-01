import 'member.dart';

class Topic {
  const Topic({
    required this.id,
    required this.title,
    required this.section,
    required this.status,
    required this.deadline,
    required this.priority,
    required this.progress,
    required this.totalTasks,
    required this.completedTasks,
    required this.members,
  });

  final String id;
  final String title;
  final String section;
  final String status;
  final String deadline;
  final String priority;
  final String progress;
  final String totalTasks;
  final String completedTasks;
  final List<Member> members;
}
