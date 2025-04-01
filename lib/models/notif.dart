class NotifItem {
  final String id;
  final String imageUrl;
  final String section;
  final String datePosted;
  final String headline;
  final bool isRead; // Add this line

  NotifItem({
    required this.id,
    required this.imageUrl,
    required this.section,
    required this.datePosted,
    required this.headline,
    this.isRead = false, // Initialize to false by default
  });
}
