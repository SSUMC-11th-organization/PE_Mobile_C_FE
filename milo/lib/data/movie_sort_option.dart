enum MovieSortOption {
  none('기본순'),
  ratingDesc('평점 높은 순'),
  yearDesc('최신순'),
  titleAsc('제목순');

  const MovieSortOption(this.label);
  final String label;
}
