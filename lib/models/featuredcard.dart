class FeaturedItem {
  const FeaturedItem({
    required this.id,
    required this.imageUrl,
    required this.section,
    required this.title,
    required this.datePosted,
    required this.pageType,
    required this.isPosted,
  });

  final String id, section, title, datePosted, pageType;
  final List<String> imageUrl;
  final bool isPosted;
}
