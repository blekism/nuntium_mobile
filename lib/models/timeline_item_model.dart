class TimelineItemModel {
  final String timelineDocId, content, comment, logOwner, dateLogged, status;

  const TimelineItemModel({
    required this.timelineDocId,
    required this.comment,
    required this.content,
    required this.logOwner,
    required this.dateLogged,
    required this.status,
  });
}
