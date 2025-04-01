class Member {
  const Member({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.role = '',
  });

  final String id;
  final String name;
  final String imageUrl;
  final String role;
}
