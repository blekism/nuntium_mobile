class NotifItem {
  final String id;
  final String postId;
  final List<String> imageUrl;
  final String section;
  final String datePosted;
  final String headline;
  final bool isRead; // Add this line
  final bool isTermly;
  final String pdfUrl;

  NotifItem({
    required this.id,
    required this.postId,
    required this.imageUrl,
    required this.section,
    required this.datePosted,
    required this.headline,
    this.isRead = false,
    this.isTermly = false,
    this.pdfUrl = '',
  });
}
