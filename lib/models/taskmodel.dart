class TaskModel {
  final String id,
      title,
      section,
      type,
      deadline,
      priority,
      assignee,
      status,
      parentId,
      sectionName;
  final bool forCaption;

  const TaskModel({
    required this.id,
    required this.title,
    required this.section,
    required this.type,
    required this.deadline,
    required this.priority,
    required this.assignee,
    required this.status,
    this.parentId = '',
    this.sectionName = '',
    this.forCaption = false,
  });
}
