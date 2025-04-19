class ViewedTask {
  final String title,
      details,
      tasktype,
      deadline,
      assigner,
      assignee,
      priority,
      content,
      headline,
      taskId,
      assigneeSec;
  final bool canCaption;

  const ViewedTask({
    required this.title,
    required this.details,
    required this.tasktype,
    required this.deadline,
    required this.assigner,
    required this.assignee,
    required this.priority,
    this.content = '',
    this.headline = '',
    required this.taskId,
    required this.assigneeSec,
    this.canCaption = false,
  });
}
