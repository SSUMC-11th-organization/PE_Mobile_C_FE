import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service);
  final TmdbMovieService _service;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];
  List<int> selectedGenreIds = [];
  List<int> lastSuccessGenreIds = [];
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String message = '';

  int _requestVersion = 0;
  bool _disposed = false;
  bool hasRetryableFailure = false;

  Future<List<TmdbMovieDto>> fetchUpToThirtyMovies({
    List<int> genreIds = const [],
  }) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < 30 && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreIds: genreIds,
      );

      for (final movie in page.results) {
        byId[movie.id] = movie;
        if (byId.length == 30) break;
      }

      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }

    return byId.values.take(30).toList();
  }

  Future<void> loadInitial() async {
    final version = ++_requestVersion;
    status = MovieListLoadStatus.loading;
    hasRetryableFailure = false;
    notifyListeners();

    try {
      genres = await _service.fetchGenres();
      final discovered = await fetchUpToThirtyMovies(
        genreIds: selectedGenreIds,
      );

      if (_disposed || version != _requestVersion) return;
      movies = discovered;
      lastSuccessGenreIds = List.of(selectedGenreIds);
      status = movies.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } on DioException {
      if (_disposed || version != _requestVersion) return;
      status = MovieListLoadStatus.error;
      message = '영화를 불러오지 못했어요. 다시 시도해 주세요.';
    }

    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  Future<void> selectGenres(List<int> genreIds) async {
    selectedGenreIds = List.of(genreIds);
    final version = ++_requestVersion;
    hasRetryableFailure = false;
    status = MovieListLoadStatus.loading;
    notifyListeners();

    try {
      final result = await fetchUpToThirtyMovies(genreIds: genreIds);
      if (_disposed || version != _requestVersion) return;
      movies = result;
      lastSuccessGenreIds = List.of(genreIds);
      status = result.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } on DioException {
      if (_disposed || version != _requestVersion) return;
      if (movies.isEmpty) {
        status = MovieListLoadStatus.error;
        message = '영화를 불러오지 못했어요. 다시 시도해 주세요.';
      } else {
        status = MovieListLoadStatus.success;
        hasRetryableFailure = true;
      }
    }

    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  Future<void> refresh() async {
    if (status == MovieListLoadStatus.loading) return;

    final version = ++_requestVersion;
    hasRetryableFailure = false;

    try {
      final result = await fetchUpToThirtyMovies(genreIds: selectedGenreIds);
      if (_disposed || version != _requestVersion) return;
      movies = result;
      lastSuccessGenreIds = List.of(selectedGenreIds);
      status = result.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } on DioException {
      if (_disposed || version != _requestVersion) return;
      if (movies.isEmpty) {
        status = MovieListLoadStatus.error;
        message = '영화를 불러오지 못했어요. 다시 시도해 주세요.';
      } else {
        hasRetryableFailure = true;
      }
    }

    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  Future<void> retry() => selectGenres(selectedGenreIds);

  void restoreLastSuccessGenres() {
    selectedGenreIds = List.of(lastSuccessGenreIds);
    hasRetryableFailure = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
