class PostActionState {
  const PostActionState({required this.isLiked, required this.isBookmarked});

  final bool isLiked;
  final bool isBookmarked;

  PostActionState copyWith({bool? isLiked, bool? isBookmarked}) {
    return PostActionState(
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
