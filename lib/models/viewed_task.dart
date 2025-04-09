class ViewedTask {
  final String title,
      details,
      tasktype,
      deadline,
      assigner,
      assignee,
      priority,
      content,
      taskId;

  const ViewedTask({
    required this.title,
    required this.details,
    required this.tasktype,
    required this.deadline,
    required this.assigner,
    required this.assignee,
    required this.priority,
    this.content = '',
    required this.taskId,
  });
}
