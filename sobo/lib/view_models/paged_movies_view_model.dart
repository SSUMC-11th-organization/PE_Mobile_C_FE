import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/models/tmdb_movie_page_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

class PagedMoviesViewModel extends ChangeNotifier with SafeNotify {
  PagedMoviesViewModel({required this.tmdbApi});

  final TmdbMovieService tmdbApi;

  LoadPhase phase = LoadPhase.idle;
  final List<TmdbMovieDto> movies = [];
  int nextPage = 1;
  int totalPages = 1;
  static const maxTmdbPage = 500;
  bool isLoadingMore = false;
  bool get hasMore => nextPage <= totalPages && nextPage <= maxTmdbPage;
  String? errorMessage;
  String? loadMoreError;
  int _requestGeneration = 0;
  ({int? genreId, String query, bool search}) _condition = (
    genreId: null,
    query: '',
    search: false,
  );

  Future<void> loadInitial({
    int? genreId,
    String query = '',
    bool searchMode = false,
  }) async {
    if (isDisposed) return;
    final normalizedQuery = query.trim();
    _condition = (genreId: genreId, query: normalizedQuery, search: searchMode);
    final generation = ++_requestGeneration;
    phase = LoadPhase.loading;
    errorMessage = null;
    loadMoreError = null;
    isLoadingMore = false;
    movies.clear();
    nextPage = 1;
    totalPages = 1;
    notifyIfAlive();

    if (searchMode && normalizedQuery.isEmpty) {
      phase = LoadPhase.idle;
      notifyIfAlive();
      return;
    }

    try {
      final result = await _fetchPage(1, _condition);
      if (generation != _requestGeneration || isDisposed) return;
      _applyFirstPage(result);
    } catch (_) {
      if (generation != _requestGeneration || isDisposed) return;
      phase = LoadPhase.error;
      errorMessage = normalizedQuery.isEmpty
          ? '영화 목록을 불러오지 못했습니다.'
          : '검색 결과를 불러오지 못했습니다.';
    } finally {
      if (generation == _requestGeneration) notifyIfAlive();
    }
  }

  Future<void> loadNextPage() async {
    if (isDisposed || isLoadingMore || !hasMore || phase != LoadPhase.ready) {
      return;
    }
    final generation = _requestGeneration;
    final pageToLoad = nextPage;
    isLoadingMore = true;
    loadMoreError = null;
    notifyIfAlive();
    try {
      final page = await _fetchPage(pageToLoad, _condition);
      if (generation != _requestGeneration || isDisposed) return;
      final seenIds = {for (final movie in movies) movie.id};
      movies.addAll(page.results.where((movie) => seenIds.add(movie.id)));
      totalPages = _boundedTotalPages(page.totalPages);
      nextPage = pageToLoad + 1;
      if (movies.isEmpty) {
        phase = LoadPhase.empty;
      }
    } catch (_) {
      if (generation != _requestGeneration || isDisposed) return;
      // nextPage는 성공했을 때만 증가해 같은 page를 재시도합니다.
      loadMoreError = '다음 영화를 불러오지 못했습니다.';
    } finally {
      if (generation == _requestGeneration && !isDisposed) {
        isLoadingMore = false;
        notifyIfAlive();
      }
    }
  }

  Future<TmdbMoviePageDto> _fetchPage(
    int page,
    ({int? genreId, String query, bool search}) condition,
  ) {
    if (condition.search) {
      return tmdbApi.searchMovies(page: page, query: condition.query);
    }
    return tmdbApi.discoverMovies(page: page, genreId: condition.genreId);
  }

  void _applyFirstPage(TmdbMoviePageDto page) {
    final unique = <int, TmdbMovieDto>{};
    for (final movie in page.results) {
      unique.putIfAbsent(movie.id, () => movie);
    }
    movies
      ..clear()
      ..addAll(unique.values);
    totalPages = _boundedTotalPages(page.totalPages);
    nextPage = 2;
    phase = movies.isEmpty ? LoadPhase.empty : LoadPhase.ready;
  }

  int _boundedTotalPages(int pages) => pages.clamp(0, maxTmdbPage).toInt();

  @override
  void dispose() {
    _requestGeneration++;
    super.dispose();
  }
}
