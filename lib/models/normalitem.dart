class NormalItem {
  const NormalItem({
    required this.id,
    required this.imageUrl,
    required this.section,
    required this.title,
    required this.datePosted,
    this.pdfUrl = '',
    required this.pageType,
    required this.isPosted,
  });

  final String id, section, title, datePosted, pdfUrl, pageType;
  final List<String> imageUrl;
  final bool isPosted;
}
