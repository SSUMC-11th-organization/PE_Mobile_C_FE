// 내가 등록한 평점 화면 상태 관리 (이번 세션 평점 + 수정·삭제·선택 삭제)
//
// 목록은 서버에서 다시 받지 않고 SessionRatingsStore(등록 응답으로 받은 평점)를 보여 줍니다.
// 수정·삭제는 v7 토큰 요청으로 보내고, 응답 결과를 저장소에 반영합니다.
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/movie.dart';
import '../data/models/rating_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'auth_view_model.dart';
import 'movie_detail_view_model.dart' show isSessionExpiredError;
import 'session_ratings_store.dart';

enum MyRatingsStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(
    this._ratingService,
    this._movieService,
    this._store,
    this._auth,
  ) {
    _store.addListener(_syncFromStore);
  }

  final RatingApiService _ratingService;
  final TmdbMovieService _movieService;
  final SessionRatingsStore _store;
  final AuthViewModel _auth;

  MyRatingsStatus status = MyRatingsStatus.idle;
  List<RatingDto> ratings = const [];

  // movieId → TMDB 영화 (제목·포스터 표시용). 한 번 받은 영화는 다시 요청하지 않음
  final Map<int, Movie> moviesById = {};
  // 평점 목록은 있고 영화 정보를 받아오는 중
  bool isLoadingMovies = false;

  // 수정·삭제 실패 등 화면에 SnackBar로 알릴 문구
  String? message;

  // ── Challenge: 여러 개 선택 삭제 ──
  final Set<int> selectedRatingIds = {};
  bool isDeletingSelected = false;

  // 삭제 요청이 진행 중인 평점 (같은 평점을 다시 삭제하지 못하게 막음)
  final Set<int> deletingRatingIds = {};
  bool isDeleting(int ratingId) =>
      isDeletingSelected || deletingRatingIds.contains(ratingId);

  bool _disposed = false;

  // 로그아웃·계정 전환 뒤 늦게 도착한 쓰기 응답인지 확인합니다.
  bool _isStale(int version) => _disposed || version != _auth.sessionVersion;

  // AUTH401_2/3/4면 세션을 정리합니다(→ Router가 /login으로 이동). 정리했으면 true.
  Future<bool> _expireIfNeeded(DioException error) async {
    if (!isSessionExpiredError(error)) return false;
    message = '로그인이 만료됐어요. 다시 로그인해 주세요.';
    await _auth.expireSession();
    return true;
  }

  Future<void> load() async {
    _syncFromStore();
    if (status == MyRatingsStatus.success) await _loadMovies();
  }

  void _syncFromStore() {
    ratings = _store.ratings;
    status = ratings.isEmpty ? MyRatingsStatus.empty : MyRatingsStatus.success;
    // 저장소에서 사라진 평점은 선택에서 뺍니다.
    final existing = {for (final rating in ratings) rating.ratingId};
    selectedRatingIds.retainWhere(existing.contains);
    _notify();
  }

  Future<void> _loadMovies() async {
    final missingIds = {
      for (final rating in ratings)
        if (!moviesById.containsKey(rating.movieId)) rating.movieId,
    };
    if (missingIds.isEmpty) return;

    isLoadingMovies = true;
    _notify();

    // 여러 영화를 동시에 요청. 한 편이 실패해도 나머지는 표시
    await Future.wait(
      missingIds.map((id) async {
        try {
          final dto = await _movieService.fetchMovieDetail(id);
          moviesById[id] = dto.toMovie();
        } on DioException {
          // 실패한 영화는 화면에서 '영화 #id'로 대신 표시
        }
      }),
    );

    isLoadingMovies = false;
    _notify();
  }

  // 수정·삭제 실패를 처리합니다. 호출한 쪽에서 다시 던집니다.
  Future<void> _handleWriteError(DioException error, int ratingId) async {
    if (await _expireIfNeeded(error)) return;
    message = writeRatingErrorMessage(error);
    // 404는 이미 지워진 평점이므로 목록에서도 뺍니다. 403은 안내만 합니다.
    if (error.response?.statusCode == 404) _store.remove(ratingId);
    _notify();
  }

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    message = null;
    final version = _auth.sessionVersion;
    try {
      final updated = await _ratingService.updateRating(
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
      if (_isStale(version)) return;
      _store.replace(updated); // 수정 result로 카드를 갱신합니다.
    } on DioException catch (error) {
      if (!_isStale(version)) await _handleWriteError(error, ratingId);
      rethrow; // 쓰기 실패일 때만 Dialog가 실패로 처리합니다.
    }
  }

  Future<void> deleteRating(int ratingId) async {
    if (isDeleting(ratingId)) return; // 연속 탭으로 같은 요청을 두 번 보내지 않음
    message = null;
    deletingRatingIds.add(ratingId);
    _notify();
    final version = _auth.sessionVersion;
    try {
      await _ratingService.deleteRating(ratingId);
      if (_isStale(version)) return;
      _store.remove(ratingId);
    } on DioException catch (error) {
      if (!_isStale(version)) await _handleWriteError(error, ratingId);
      rethrow;
    } finally {
      deletingRatingIds.remove(ratingId);
      _notify();
    }
  }

  void toggleSelected(int ratingId) {
    if (isDeletingSelected) return;
    if (!selectedRatingIds.remove(ratingId)) selectedRatingIds.add(ratingId);
    _notify();
  }

  void clearSelection() {
    if (isDeletingSelected) return;
    selectedRatingIds.clear();
    _notify();
  }

  Future<void> deleteSelectedRatings() async {
    if (isDeletingSelected || selectedRatingIds.isEmpty) return;
    message = null;
    isDeletingSelected = true;
    _notify();
    var failed = 0;
    final version = _auth.sessionVersion;
    try {
      for (final ratingId in selectedRatingIds.toList()) {
        try {
          await _ratingService.deleteRating(ratingId);
          if (_isStale(version)) return;
          _store.remove(ratingId);
        } on DioException catch (error) {
          if (_isStale(version)) return;
          // 세션이 만료되면 남은 항목은 요청하지 않고 멈춥니다.
          if (await _expireIfNeeded(error)) return;
          if (error.response?.statusCode == 404) {
            _store.remove(ratingId); // 이미 지워진 평점
          } else {
            failed++; // 실패한 항목은 선택 상태를 유지합니다.
          }
        }
      }
    } finally {
      isDeletingSelected = false;
      _notify(); // 예상하지 못한 오류에도 로딩을 해제합니다.
    }
    if (failed > 0) {
      message = '$failed개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.';
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _store.removeListener(_syncFromStore);
    super.dispose();
  }
}
