// 내가 등록한 평점 화면 상태 관리
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/movie.dart';
import '../data/models/rating_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

// 로그인 기능이 없어 학습용 회원(1번)으로 고정
const sampleMemberId = 1;

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

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
