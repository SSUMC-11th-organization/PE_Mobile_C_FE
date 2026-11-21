import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_request.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../services/rating_api_service.dart';
import 'auth_view_model.dart';
import 'sign_up_view_model.dart';
import 'session_ratings_store.dart';

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._ratingService,
    AuthViewModel auth,
    this._sessionRatings,
    this.movie,
  ) : _auth = auth,
      _observedSessionVersion = auth.sessionVersion {
    _auth.addListener(_onAuthChanged);
  }

  final RatingApiService _ratingService;
  final AuthViewModel _auth;
  final SessionRatingsStore _sessionRatings;
  final TmdbMovieDto movie;
  int _observedSessionVersion;

  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  String? submitErrorCode;
  RatingDto? createdRating;
  bool _disposed = false;

  Future<void> createRating({required int score, String? comment}) async {
    if (_disposed || submitStatus == SubmitStatus.submitting) return;
    if (_auth.status != AuthStatus.signedIn) {
      submitStatus = SubmitStatus.error;
      submitMessage = '로그인 후 평점을 남길 수 있어요.';
      notifyListeners();
      return;
    }

    final sessionVersion = _auth.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    submitErrorCode = null;
    notifyListeners();

    try {
      final rating = await _ratingService.createRating(
        CreateRatingRequest(movieId: movie.id, score: score, comment: comment),
      );

      if (!_isCurrentSession(sessionVersion)) {
        _discardStaleResult();
        return;
      }
      createdRating = rating;
      _sessionRatings.add(rating);
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (!_isCurrentSession(sessionVersion)) {
        _discardStaleResult();
        return;
      }

      submitStatus = SubmitStatus.error;
      submitErrorCode = apiErrorCode(error);
      submitMessage = writeErrorMessage(error);
      if (_isExpiredAuthCode(submitErrorCode)) {
        notifyListeners();
        await _auth.expireSession();
        return;
      }
    } on StateError {
      if (!_isCurrentSession(sessionVersion)) {
        _discardStaleResult();
        return;
      }

      submitStatus = SubmitStatus.error;
      submitMessage = '등록 결과를 확인하지 못했습니다. 내 평점 목록을 확인해 주세요.';
    }

    if (!_disposed) notifyListeners();
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
    createdRating = null;
    submitStatus = SubmitStatus.idle;
    submitMessage = null;
    submitErrorCode = null;
    notifyListeners();
  }

  void _discardStaleResult() {
    if (_disposed) return;
    createdRating = null;
    submitStatus = SubmitStatus.idle;
    submitMessage = null;
    submitErrorCode = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
