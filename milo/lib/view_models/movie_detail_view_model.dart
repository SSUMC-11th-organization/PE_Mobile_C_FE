import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/movie_record_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/models/movie_record_models.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

enum MovieDetailLoadStatus { idle, loading, success, error }

enum MovieRecordOutcome { saved, keepOpen, dismiss }

class MovieRecordResult {
  const MovieRecordResult(this.outcome, [this.message]);

  final MovieRecordOutcome outcome;
  final String? message;
}

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(
    this._ratingService,
    this._movieRecordService,
    this._auth,
    this.movie,
  );

  final RatingApiService _ratingService;
  final MovieRecordApiService _movieRecordService;
  final AuthViewModel _auth;
  final TmdbMovieDto movie;

  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<bool> createRating({required int score, String? comment}) async {
    if (_disposed || submitStatus == SubmitStatus.submitting) {
      return false; // 중복 탭 방지
    }

    final version = _auth.sessionVersion; // 요청 시점의 세션 버전
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    _notify();

    try {
      await _ratingService.createRating(
        CreateRatingRequest(movieId: movie.id, score: score, comment: comment),
      );
      if (_disposed || version != _auth.sessionVersion) {
        return false; // 이전 세션의 늦은 응답 무시
      }
      submitStatus = SubmitStatus.success;
      _notify();
      return true;
    } on DioException catch (error) {
      if (_disposed || version != _auth.sessionVersion) return false;
      final code = apiErrorCode(error);
      if (code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4') {
        await _auth.expireSession(); // 로그아웃·이동은 Router가 처리
        return false;
      }
      submitStatus = SubmitStatus.error;
      submitMessage = switch (code) {
        'RATING409_1' => '이미 평점을 남긴 영화예요. 기존 기록을 확인해 주세요.',
        'RATING403_1' => '본인이 작성한 평점만 변경할 수 있어요.',
        'RATING404_1' => '존재하지 않는 평점이에요.',
        _ => apiErrorMessage(error) ?? '요청에 실패했어요. 잠시 후 다시 시도해 주세요.',
      };
      _notify();
      return false;
    } catch (_) {
      // 응답 파싱 실패 등. 여기서 처리하지 않으면 submitting 상태로 멈춥니다.
      if (_disposed || version != _auth.sessionVersion) return false;
      submitStatus = SubmitStatus.error;
      submitMessage = '요청을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.';
      _notify();
      return false;
    }
  }

  Future<MovieRecordResult> createMovieRecord({
    required int score,
    String? comment,
    required bool addToFavorites,
  }) async {
    if (_disposed) return const MovieRecordResult(MovieRecordOutcome.dismiss);
    if (submitStatus == SubmitStatus.submitting) {
      return const MovieRecordResult(
        MovieRecordOutcome.keepOpen,
        '저장 중입니다. 잠시만 기다려 주세요.',
      ); // 중복 탭 방지
    }

    final version = _auth.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    _notify();

    try {
      await _movieRecordService.createMovieRecord(
        CreateMovieRecordRequest(
          movieId: movie.id,
          score: score,
          comment: comment,
          addToFavorites: addToFavorites,
        ),
      );
      if (_disposed || version != _auth.sessionVersion) {
        return const MovieRecordResult(MovieRecordOutcome.dismiss);
      }
      submitStatus = SubmitStatus.success;
      _notify();
      return const MovieRecordResult(MovieRecordOutcome.saved);
    } on DioException catch (error) {
      if (_disposed || version != _auth.sessionVersion) {
        return const MovieRecordResult(MovieRecordOutcome.dismiss);
      }
      final code = apiErrorCode(error);
      if (code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4') {
        await _auth.expireSession(); // 로그아웃·이동은 Router가 처리
        return const MovieRecordResult(MovieRecordOutcome.dismiss);
      }

      submitStatus = SubmitStatus.error;
      final result = switch (code) {
        // 서버가 한 트랜잭션으로 처리하므로 아래 오류에서는 아무것도 저장되지 않습니다.
        'RATING409_1' => const MovieRecordResult(
          MovieRecordOutcome.dismiss,
          '이미 평점을 남긴 영화예요. 마이페이지에서 기존 평점을 확인해 주세요.',
        ),
        'FAVORITE409_1' => const MovieRecordResult(
          MovieRecordOutcome.dismiss,
          '이미 즐겨찾기한 영화예요. 평점은 저장되지 않았어요.',
        ),
        'MEMBER404_1' => const MovieRecordResult(
          MovieRecordOutcome.dismiss,
          '회원 정보를 찾을 수 없어요. 다시 로그인해 주세요.',
        ),
        // 입력값 오류: Dialog를 열어 둔 채 이유를 보여 줍니다.
        'COMMON400' => MovieRecordResult(
          MovieRecordOutcome.keepOpen,
          apiErrorMessage(error) ?? '입력값을 확인해 주세요.',
        ),
        _ when error.response == null => const MovieRecordResult(
          MovieRecordOutcome.keepOpen,
          '네트워크 연결을 확인한 뒤 다시 시도해 주세요.',
        ),
        _ => MovieRecordResult(
          MovieRecordOutcome.keepOpen,
          apiErrorMessage(error) ?? '저장하지 못했어요. 잠시 후 다시 시도해 주세요.',
        ),
      };
      submitMessage = result.message;
      _notify();
      return result;
    } catch (_) {
      if (_disposed || version != _auth.sessionVersion) {
        return const MovieRecordResult(MovieRecordOutcome.dismiss);
      }
      submitStatus = SubmitStatus.error;
      submitMessage = '응답을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.';
      _notify();
      return MovieRecordResult(MovieRecordOutcome.keepOpen, submitMessage);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
