// 영화 상세 화면 상태 관리 (토큰 기반 평점 등록)
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/movie.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_request.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'session_ratings_store.dart';
import 'sign_up_view_model.dart' show SubmitStatus;

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._ratingService,
    this._auth,
    this._sessionRatings,
    this.movie,
  );
  final RatingApiService _ratingService;
  final AuthViewModel _auth;
  // 등록한 평점을 '내 평점' 화면에서 수정·삭제할 수 있게 모아 둡니다.
  final SessionRatingsStore _sessionRatings;
  final Movie movie;
  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  // 등록 응답(result)으로 받은 내 평점. 화면의 '내 평점' 카드가 이 값을 보여 줍니다.
  RatingDto? myRating;
  bool _disposed = false;

  bool get isSignedIn => _auth.status == AuthStatus.signedIn;

  // 로그아웃·계정 전환 뒤 늦게 도착한 응답인지 확인합니다.
  bool _isStale(int version) =>
      _disposed || version != _auth.sessionVersion || !isSignedIn;

  Future<void> createRating({required int score, String? comment}) async {
    if (submitStatus == SubmitStatus.submitting) return;
    if (!isSignedIn) {
      submitStatus = SubmitStatus.error;
      submitMessage = '로그인이 필요해요.';
      notifyListeners();
      return;
    }
    final version = _auth.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();
    try {
      // path와 body에 memberId가 없고, Authorization 헤더로 회원을 구분합니다.
      final created = await _ratingService.createRating(
        CreateRatingRequest(movieId: movie.id, score: score, comment: comment),
      );
      if (_isStale(version)) return;
      myRating = created;
      _sessionRatings.add(created);
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_isStale(version)) return;
      submitStatus = SubmitStatus.error;
      if (isSessionExpiredError(error)) {
        submitMessage = '로그인이 만료됐어요. 다시 로그인해 주세요.';
        // 세션 정리 → signedOut → Router가 /login으로 이동
        await _auth.expireSession();
        return;
      }
      // 403·409 등은 안내만 하고 로그인 상태를 유지합니다.
      submitMessage = writeRatingErrorMessage(error);
    } on StateError {
      if (_isStale(version)) return;
      submitStatus = SubmitStatus.error;
      submitMessage = '등록 결과를 확인하지 못했어요. 내 평점 목록에서 확인해 주세요.';
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

// 토큰 만료·무효로 세션을 정리해야 하는 401인지 확인합니다.
bool isSessionExpiredError(DioException error) {
  final code = apiErrorCode(error);
  return code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
}
