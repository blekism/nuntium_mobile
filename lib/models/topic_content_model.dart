class TopicContentModel {
  final String topicId,
      writingId,
      pubmatId,
      headline,
      pubmatStatus,
      writtenStatus,
      writtenContent;
  final List<String> pubmatUrls;

  const TopicContentModel({
    required this.topicId,
    required this.writingId,
    required this.pubmatId,
    required this.pubmatUrls,
    required this.headline,
    required this.writtenContent,
    required this.pubmatStatus,
    required this.writtenStatus,
  });
}
