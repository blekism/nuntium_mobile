class PostModel {
  const PostModel({
    required this.title,
    required this.section,
    required this.members,
    required this.content,
    required this.time,
    required this.postId,
  });

  final String title, section, members, content, time, postId;
}
