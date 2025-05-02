class ViewedTask {
  final String title,
      details,
      tasktype,
      deadline,
      assigner,
      assignee,
      content,
      headline,
      taskId,
      assigneeSec,
      assigneeName,
      comments,
      status;
  final bool canCaption, hasStarted;
  final int projectStep, totalSubtask;

  const ViewedTask({
    required this.title,
    required this.details,
    required this.tasktype,
    required this.deadline,
    required this.assigner,
    required this.assignee,
    this.content = '',
    this.headline = '',
    required this.taskId,
    required this.assigneeSec,
    required this.assigneeName,
    required this.comments,
    this.canCaption = false,
    required this.hasStarted,
    required this.projectStep,
    required this.totalSubtask,
    required this.status,
  });
}
