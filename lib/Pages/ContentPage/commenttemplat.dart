import 'Package:flutter/material.dart';

class CommentTemplate extends StatefulWidget {
  final String profilePic;
  final String commenter;
  final String comment;

  const CommentTemplate(
      {super.key,
      required this.profilePic,
      required this.commenter,
      required this.comment});

  @override
  State<CommentTemplate> createState() => CommentTemplateState();
}

class CommentTemplateState extends State<CommentTemplate> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundImage:
            AssetImage('assets/images/nudasma.jpg'), //AssetImage(profilePic)
      ),
      title: Text(widget.commenter),
      subtitle: Text(widget.comment),
    );
  }
}
