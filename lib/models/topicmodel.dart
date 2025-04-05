class TopicModel {
  final String id, title, section, status, deadline, priority;
  final int completedSubtask, totalSubtask;

  const TopicModel({
    required this.id,
    required this.title,
    required this.section,
    required this.status,
    required this.deadline,
    required this.priority,
    required this.completedSubtask,
    required this.totalSubtask,
  });
}
