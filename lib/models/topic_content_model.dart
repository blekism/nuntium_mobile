class TopicContentModel {
  final String topicId,
      writingId,
      pubmatId,
      pubmatUrl,
      headline,
      pubmatStatus,
      writtenStatus,
      writtenContent;

  const TopicContentModel({
    required this.topicId,
    required this.writingId,
    required this.pubmatId,
    required this.pubmatUrl,
    required this.headline,
    required this.writtenContent,
    required this.pubmatStatus,
    required this.writtenStatus,
  });
}
