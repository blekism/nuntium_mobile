import 'member.dart';

class Topic {
  const Topic({
    required this.id,
    required this.title,
    required this.section,
    required this.status,
    required this.deadline,
    required this.priority,
    required this.totalSubtask,
    required this.completedSubtask,
    this.members = const [],
    this.otherMembers = 0,
  });

  final String id;
  final String title;
  final String section;
  final String status;
  final String deadline;
  final String priority;
  final int totalSubtask;
  final int completedSubtask;
  final List<Member> members;
  final int otherMembers;
}
