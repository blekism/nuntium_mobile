class Comment {
  const Comment({
    required this.commentId,
    required this.imageUrl,
    required this.commenter,
    required this.comment,
    required this.date,
  });

  final String commentId, imageUrl, commenter, comment, date;
}
