import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../services/tmdb_movie_service.dart';

enum MovieListLoadStatus {
  idle,
  loading,
  success,
  empty,
  error,
}

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service);

  final TmdbMovieService _service;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];

  int? selectedGenreId;

  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;

  bool _disposed = false;

  Future<List<TmdbMovieDto>> fetchUpToThirtyMovies({
    int? genreId,
  }) async {
    final byId = <int, TmdbMovieDto>{};

    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < 30 && hasNextPage && !_disposed) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreId: genreId,
      );

      if (_disposed) return const [];

      for (final movie in page.results) {
        byId[movie.id] = movie;

        if (byId.length == 30) break;
      }

      hasNextPage =
          pageNumber < page.totalPages && page.results.isNotEmpty;

      pageNumber++;
    }

    return byId.values.toList();
  }

  Future<void> loadInitial() async {
    if (_disposed || status == MovieListLoadStatus.loading) return;

    status = MovieListLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final loadedGenres = await _service.fetchGenres();

      if (_disposed) return;

      genres = loadedGenres;

      final result = await fetchUpToThirtyMovies(
        genreId: selectedGenreId,
      );

      if (_disposed) return;

      movies = result;

      status = movies.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } catch (_) {
      if (_disposed) return;

      status = MovieListLoadStatus.error;
      message = '영화를 불러오지 못했어요. 다시 시도해주세요.';
    }

    notifyListeners();
  }

  Future<void> selectGenre(int? genreId) async {
    if (_disposed || status == MovieListLoadStatus.loading) return;

    selectedGenreId = genreId;
    status = MovieListLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final result = await fetchUpToThirtyMovies(
        genreId: genreId,
      );

      if (_disposed) return;

      movies = result;

      status = movies.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } catch (_) {
      if (_disposed) return;

      status = MovieListLoadStatus.error;
      message = '해당 장르 영화를 불러오지 못했어요.';
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}