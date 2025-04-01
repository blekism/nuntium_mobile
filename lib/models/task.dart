class Task {
  const Task({
    required this.id,
    required this.title,
    required this.section,
    required this.type,
    required this.status,
    required this.deadline,
    required this.priority,
    required this.member1,
    required this.member2,
    required this.memberCount,
  });

  final String id;
  final String title;
  final String section;
  final String type;
  final String status;
  final String deadline;
  final String priority;
  final String member1;
  final String member2;
  final int memberCount;
}
