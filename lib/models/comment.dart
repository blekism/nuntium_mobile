class Comment {
  const Comment(
      {required this.commentId,
      required this.imageUrl,
      required this.commenter,
      required this.comment,
      required this.date,
      required this.userId});

  final String commentId, imageUrl, commenter, comment, date, userId;
}
