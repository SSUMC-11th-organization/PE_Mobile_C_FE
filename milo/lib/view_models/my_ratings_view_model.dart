import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(
    this._service,
    this._movieService,
    this._auth,
    this.memberId,
  );
  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final AuthViewModel _auth;
  final int memberId;
  final Map<int, TmdbMovieDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;
  String? refreshWarning;
  final Set<int> selectedRatingIds = {};
  bool isDeletingSelected = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;
  String? message;

  bool isSelectionMode = false;

  void startSelection() {
    if (isDeletingSelected) return;
    isSelectionMode = true;
    selectedRatingIds.clear();
    _notify();
  }

  void cancelSelection() {
    if (isDeletingSelected) return;
    isSelectionMode = false;
    selectedRatingIds.clear();
    _notify();
  }

  /// dispose 뒤에 늦게 끝난 요청이 notifyListeners를 부르지 않게 합니다.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void toggleSelected(int ratingId) {
    if (!selectedRatingIds.remove(ratingId)) selectedRatingIds.add(ratingId);
    _notify();
  }

  /// 401(AUTH401_2/3/4)이면 세션을 정리하고 true를 돌려줍니다.
  /// 요청을 보낸 뒤 세션이 바뀌었다면(다른 계정으로 재로그인 등) 새 세션은 지우지 않습니다.
  Future<bool> _handleSessionExpired(DioException error, int session) async {
    final code = apiErrorCode(error);
    final expired =
        code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
    if (!expired) return false;
    if (session == _auth.sessionVersion) await _auth.expireSession();
    return true;
  }

  Future<void> load() async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();
    try {
      final rawRatings = await _service.fetchMyRatings(memberId);
      if (_disposed || version != _requestVersion) return;
      final entries = <RatingWithMovie>[];
      var missingMovies = 0;
      // 같은 movieId는 캐시를 사용하고, 영화 조회 실패가 평점 목록을 지우지 않습니다.
      for (final rating in rawRatings) {
        if (_disposed || version != _requestVersion) return;
        if (!_movieCache.containsKey(rating.movieId)) {
          try {
            _movieCache[rating.movieId] = await _movieService.findMovieById(
              rating.movieId,
            );
          } on DioException {
            // 일시적 네트워크 실패는 캐시하지 않습니다. 다음 로딩에서 재시도합니다.
          }
        }
        final movie = _movieCache[rating.movieId];
        if (movie == null) missingMovies++;
        entries.add(RatingWithMovie(rating: rating, movie: movie));
      }
      if (_disposed || version != _requestVersion) return;
      ratings = entries;
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (missingMovies > 0) {
        message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
      }
    } on DioException catch (error) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = writeErrorMessage(error);
    } catch (_) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = '알 수 없는 오류가 발생했어요.';
    }
    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  Future<void> _refreshAfterWrite() async {
    await load(); // 6주차 load()는 GET 실패를 status=error로 기록합니다.
    if (status == MyRatingsLoadStatus.error) {
      refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
      _notify();
    } else {
      refreshWarning = null;
    }
  }

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final session = _auth.sessionVersion;
    try {
      await _service.updateRating(
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
    } on DioException catch (error) {
      // 세션 만료: 정리는 Router가 처리하고, Dialog는 실패로 끝냅니다.
      if (await _handleSessionExpired(error, session)) rethrow;
      final errorMessage = writeErrorMessage(error);
      if (shouldRefreshAfterRatingError(error)) await load();
      message = errorMessage; // load()가 message를 지우므로 그 뒤에 다시 설정합니다.
      _notify();
      rethrow; // 쓰기 실패일 때만 Dialog가 실패로 처리합니다.
    }
    await _refreshAfterWrite(); // GET 실패는 저장 실패로 다시 던지지 않습니다.
  }

  Future<void> deleteRating(int ratingId) async {
    final session = _auth.sessionVersion;
    try {
      await _service.deleteRating(ratingId);
    } on DioException catch (error) {
      if (await _handleSessionExpired(error, session)) rethrow;
      final errorMessage = writeErrorMessage(error);
      if (shouldRefreshAfterRatingError(error)) await load();
      message = errorMessage;
      _notify();
      rethrow;
    }
    await _refreshAfterWrite();
  }

  Future<void> deleteSelectedRatings() async {
    if (isDeletingSelected || selectedRatingIds.isEmpty) return;
    final session = _auth.sessionVersion;
    isDeletingSelected = true;
    notifyListeners();
    var failed = 0;
    var expired = false;
    try {
      for (final ratingId in selectedRatingIds.toList()) {
        try {
          await _service.deleteRating(ratingId);
          selectedRatingIds.remove(ratingId);
        } on DioException catch (error) {
          if (await _handleSessionExpired(error, session)) {
            expired = true;
            break; // 토큰이 무효면 나머지 요청도 같은 401이므로 중단합니다.
          }
          failed++;
          // 실패한 항목은 선택 상태를 유지합니다.
        }
      }
    } finally {
      isDeletingSelected = false;
      _notify(); // 예상하지 못한 오류에도 로딩을 해제합니다.
    }
    if (expired) return; // Router가 /login으로 보냅니다. 목록 새로고침은 하지 않습니다.
    await _refreshAfterWrite(); // GET 실패는 삭제 성공 여부와 분리합니다.
    if (failed > 0) {
      message = '$failed개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.';
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
