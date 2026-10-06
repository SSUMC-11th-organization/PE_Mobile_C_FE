import 'movie.dart';

enum MovieSort {
  recommended('기본순'),
  rating('평점순'),
  latest('최신순'),
  title('가나다순');

  const MovieSort(this.label);

  final String label;

  List<Movie> apply(List<Movie> movies) {
    final sorted = [...movies];
    switch (this) {
      case MovieSort.recommended:
        break;
      case MovieSort.rating:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
      case MovieSort.latest:
        sorted.sort((a, b) => b.year.compareTo(a.year));
      case MovieSort.title:
        sorted.sort((a, b) => a.title.compareTo(b.title));
    }
    return sorted;
  }

  static MovieSort fromName(String? name) {
    return MovieSort.values.firstWhere(
      (sort) => sort.name == name,
      orElse: () => MovieSort.recommended,
    );
  }
}
