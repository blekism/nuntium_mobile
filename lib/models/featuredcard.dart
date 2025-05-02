class FeaturedItem {
  const FeaturedItem({
    required this.id,
    required this.imageUrl,
    required this.section,
    required this.title,
    required this.datePosted,
  });

  final String id, section, title, datePosted;
  final List<String> imageUrl;
}
