// 내가 등록한 평점 화면 상태 관리 (조회 + 수정·삭제·선택 삭제)
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/movie.dart';
import '../data/models/rating_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsStatus { idle, loading, success, empty, error }

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this._ratingService, this._movieService, this.memberId);

  final RatingApiService _ratingService;
  final TmdbMovieService _movieService;
  final int memberId;

  MyRatingsStatus status = MyRatingsStatus.idle;
  List<RatingDto> ratings = const [];
  String? errorMessage;

  // movieId → TMDB 영화 (제목·포스터 표시용). 한 번 받은 영화는 다시 요청하지 않음
  final Map<int, Movie> moviesById = {};
  // 평점 목록은 받았고 영화 정보를 받아오는 중
  bool isLoadingMovies = false;

  // 수정·삭제 실패 등 화면에 SnackBar로 알릴 문구
  String? message;
  // 쓰기는 성공했지만 목록 재조회가 실패했을 때의 안내
  String? refreshWarning;

  // ── Challenge: 여러 개 선택 삭제 ──
  final Set<int> selectedRatingIds = {};
  bool isDeletingSelected = false;

  // 삭제 요청이 진행 중인 평점 (같은 평점을 다시 삭제하지 못하게 막음)
  final Set<int> deletingRatingIds = {};
  bool isDeleting(int ratingId) =>
      isDeletingSelected || deletingRatingIds.contains(ratingId);

  bool _disposed = false;

  Future<void> load() async {
    status = MyRatingsStatus.loading;
    errorMessage = null;
    _notify();

    try {
      ratings = await _ratingService.fetchMyRatings(memberId);
      status = ratings.isEmpty
          ? MyRatingsStatus.empty
          : MyRatingsStatus.success;
    } on DioException catch (error) {
      ratings = const [];
      status = MyRatingsStatus.error;
      errorMessage = writeMyRatingsErrorMessage(error);
    }
    _notify();

    // 목록을 먼저 보여주고, 제목·포스터는 뒤이어 채움
    if (status == MyRatingsStatus.success) await _loadMovies();
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

  Future<void> _refreshAfterWrite() async {
    await load(); // load()는 GET 실패를 status=error로 기록합니다.
    if (status == MyRatingsStatus.error) {
      refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.';
      _notify();
    } else {
      refreshWarning = null;
      // 서버에 더 이상 없는 평점은 선택에서 뺍니다.
      final existing = {for (final rating in ratings) rating.ratingId};
      selectedRatingIds.retainWhere(existing.contains);
    }
  }

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    message = null;
    try {
      await _ratingService.updateRating(
        memberId: memberId,
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
    } on DioException catch (error) {
      message = writeRatingErrorMessage(error);
      _notify();
      if (shouldRefreshAfterRatingError(error)) await load();
      rethrow; // 쓰기 실패일 때만 Dialog가 실패로 처리합니다.
    }
    await _refreshAfterWrite(); // GET 실패는 저장 실패로 다시 던지지 않습니다.
  }

  Future<void> deleteRating(int ratingId) async {
    if (isDeleting(ratingId)) return; // 연속 탭으로 같은 요청을 두 번 보내지 않음
    message = null;
    deletingRatingIds.add(ratingId);
    _notify();
    try {
      await _ratingService.deleteRating(memberId: memberId, ratingId: ratingId);
    } on DioException catch (error) {
      message = writeRatingErrorMessage(error);
      _notify();
      if (shouldRefreshAfterRatingError(error)) await load();
      rethrow;
    } finally {
      deletingRatingIds.remove(ratingId);
      _notify();
    }
    selectedRatingIds.remove(ratingId);
    await _refreshAfterWrite();
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
    try {
      for (final ratingId in selectedRatingIds.toList()) {
        try {
          await _ratingService.deleteRating(
            memberId: memberId,
            ratingId: ratingId,
          );
          selectedRatingIds.remove(ratingId);
        } on DioException {
          failed++;
          // 실패한 항목은 선택 상태를 유지합니다.
        }
      }
    } finally {
      isDeletingSelected = false;
      _notify(); // 예상하지 못한 오류에도 로딩을 해제합니다.
    }
    await _refreshAfterWrite(); // GET 실패는 삭제 성공 여부와 분리합니다.
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
    super.dispose();
  }
}
