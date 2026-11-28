import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'auth_view_model.dart';
import 'session_ratings_store.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(
    this._service,
    this._movieService,
    this._store,
    AuthViewModel auth,
  ) : _auth = auth,
      _observedSessionVersion = auth.sessionVersion {
    _auth.addListener(_onAuthChanged);
    _store.addListener(_syncFromStore);
    _syncFromStore();
  }

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final SessionRatingsStore _store;
  final AuthViewModel _auth;
  int _observedSessionVersion;
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;
  String? messageCode;
  String? refreshWarning;

  Future<void> load() async {
    if (_disposed || _auth.status != AuthStatus.signedIn) return;
    _syncFromStore();
    if (ratings.isNotEmpty) await _loadMoviesForRatings();
  }

  Future<void> _refreshAfterWrite(int sessionVersion) async {
    if (!_isCurrentSession(sessionVersion)) return;
    _syncFromStore();
    if (ratings.isNotEmpty) await _loadMoviesForRatings();
  }

  void _syncFromStore() {
    if (_disposed) return;
    final rawRatings = _store.ratings;
    ratings = [
      for (final rating in rawRatings)
        RatingWithMovie(rating: rating, movie: _movieCache[rating.movieId]),
    ];
    final existingIds = {for (final rating in rawRatings) rating.ratingId};
    selectedRatingIds.retainWhere(existingIds.contains);
    status = rawRatings.isEmpty
        ? MyRatingsLoadStatus.empty
        : MyRatingsLoadStatus.success;
    message = null;
    messageCode = null;
    refreshWarning = null;
    notifyListeners();
  }

  Future<void> _loadMoviesForRatings() async {
    final requestVersion = ++_requestVersion;
    final sessionVersion = _auth.sessionVersion;
    var missingMovies = 0;
    for (final entry in ratings) {
      if (!_isCurrentSession(sessionVersion) ||
          requestVersion != _requestVersion) {
        return;
      }
      final movieId = entry.rating.movieId;
      if (!_movieCache.containsKey(movieId)) {
        try {
          _movieCache[movieId] = await _movieService.findMovieById(movieId);
        } on DioException {
          // TMDB 오류는 평점 목록을 지우지 않습니다. 다음 새로고침에서 재시도합니다.
        }
      }
      if (_movieCache[movieId] == null) missingMovies++;
    }
    if (!_isCurrentSession(sessionVersion) ||
        requestVersion != _requestVersion) {
      return;
    }
    ratings = [
      for (final rating in _store.ratings)
        RatingWithMovie(rating: rating, movie: _movieCache[rating.movieId]),
    ];
    if (missingMovies > 0) {
      message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
    }
    notifyListeners();
  }

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    if (_disposed || _auth.status != AuthStatus.signedIn) return;
    final sessionVersion = _auth.sessionVersion;
    message = null;
    messageCode = null;

    try {
      final updated = await _service.updateRating(
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
      if (!_isCurrentSession(sessionVersion)) {
        _discardStaleData();
        return;
      }

      _store.replace(updated);
    } on DioException catch (error) {
      await _handleWriteError(error, sessionVersion);
      rethrow;
    }

    await _refreshAfterWrite(sessionVersion);
  }

  Future<void> deleteRating(int ratingId) async {
    if (_disposed || _auth.status != AuthStatus.signedIn) return;
    final sessionVersion = _auth.sessionVersion;
    message = null;
    messageCode = null;

    try {
      await _service.deleteRating(ratingId);
      if (!_isCurrentSession(sessionVersion)) {
        _discardStaleData();
        return;
      }
      _store.remove(ratingId);
      selectedRatingIds.remove(ratingId);
    } on DioException catch (error) {
      await _handleWriteError(error, sessionVersion);
      rethrow;
    }

    await _refreshAfterWrite(sessionVersion);
  }

  Future<void> _handleWriteError(DioException error, int sessionVersion) async {
    if (!_isCurrentSession(sessionVersion)) {
      _discardStaleData();
      return;
    }

    messageCode = apiErrorCode(error);
    if (_isExpiredAuthCode(messageCode)) {
      await _auth.expireSession();
      return;
    }

    message = writeErrorMessage(error);
    notifyListeners();

    if (shouldRefreshAfterRatingError(error)) {
      await load();
    }
  }

  final Set<int> selectedRatingIds = {};
  bool isDeletingSelected = false;

  void toggleRatingSelection(int ratingId) {
    if (_disposed || isDeletingSelected) return;
    if (!selectedRatingIds.add(ratingId)) {
      selectedRatingIds.remove(ratingId);
    }
    notifyListeners();
  }

  Future<void> deleteSelectedRatings() async {
    if (_disposed ||
        _auth.status != AuthStatus.signedIn ||
        isDeletingSelected ||
        selectedRatingIds.isEmpty) {
      return;
    }
    final sessionVersion = _auth.sessionVersion;
    message = null;
    messageCode = null;
    refreshWarning = null;
    isDeletingSelected = true;
    notifyListeners();
    var failed = 0;
    final failureMessages = <String>{};
    try {
      for (final ratingId in selectedRatingIds.toList()) {
        try {
          await _service.deleteRating(ratingId);
          if (!_isCurrentSession(sessionVersion)) {
            _discardStaleData();
            return;
          }
          selectedRatingIds.remove(ratingId);
          _store.remove(ratingId);
        } on DioException catch (error) {
          if (!_isCurrentSession(sessionVersion)) {
            _discardStaleData();
            return;
          }
          messageCode = apiErrorCode(error);
          if (_isExpiredAuthCode(messageCode)) {
            await _auth.expireSession();
            return;
          }
          failed++;
          failureMessages.add(writeErrorMessage(error));
          // 실패한 항목은 선택 상태를 유지합니다.
        }
      }
    } finally {
      isDeletingSelected = false;
      if (!_disposed) notifyListeners();
    }
    if (!_isCurrentSession(sessionVersion)) return;
    await _refreshAfterWrite(sessionVersion);
    if (_isCurrentSession(sessionVersion) && failed > 0) {
      messageCode = 'RATING_WRITE_FAILURES';
      message = failureMessages.isEmpty
          ? '$failed개 항목을 삭제하지 못했습니다.'
          : '$failed개 항목을 삭제하지 못했습니다. ${failureMessages.join(' ')}';
      notifyListeners();
    }
  }

  bool _isCurrentSession(int version) =>
      !_disposed &&
      version == _auth.sessionVersion &&
      _auth.status == AuthStatus.signedIn;

  bool _isExpiredAuthCode(String? code) =>
      code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';

  void _onAuthChanged() {
    if (_disposed || _observedSessionVersion == _auth.sessionVersion) return;
    _observedSessionVersion = _auth.sessionVersion;
    _discardStaleData();
  }

  void _discardStaleData() {
    if (_disposed) return;
    _requestVersion++;
    ratings = const [];
    selectedRatingIds.clear();
    message = null;
    messageCode = null;
    refreshWarning = null;
    status = MyRatingsLoadStatus.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    _store.removeListener(_syncFromStore);
    _requestVersion++;
    super.dispose();
  }
}
