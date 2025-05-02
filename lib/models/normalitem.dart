class NormalItem {
  const NormalItem({
    required this.id,
    required this.imageUrl,
    required this.section,
    required this.title,
    required this.datePosted,
    this.pdfUrl = '',
  });

  final String id, section, title, datePosted, pdfUrl;
  final List<String> imageUrl;
}
