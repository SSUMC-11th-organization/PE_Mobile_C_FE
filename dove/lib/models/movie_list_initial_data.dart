import 'movie.dart';
import 'movie_sort.dart';

class MovieListInitialData {
  const MovieListInitialData({
    required this.movies,
    required this.selectedGenre,
    required this.selectedSort,
  });

  final List<Movie> movies;
  final String selectedGenre;
  final MovieSort selectedSort;
}
