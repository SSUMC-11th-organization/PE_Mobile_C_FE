import 'package:dio/dio.dart';

import '../core/network/api_error.dart';
import '../data/models/common_response.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_request.dart';

RatingDto parseRatingResult(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw StateError('평점 응답 형식이 올바르지 않습니다.');
  }

  final common = CommonResponse<RatingDto>.fromJson(
    data,
    (value) => RatingDto.fromJson(value as Map<String, dynamic>),
  );
  final rating = common.result;
  if (rating == null) {
    throw StateError('평점 result가 없습니다.');
  }
  return rating;
}

List<RatingDto> parseRatingList(Object? data) {
  if (data is! List) {
    throw StateError('평점 목록 응답은 배열이어야 합니다.');
  }

  return data
      .map((value) => RatingDto.fromJson(value as Map<String, dynamic>))
      .toList();
}

class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);

  final Dio _publicDio;
  final Dio _authDio;

  // 유저별 평점 조회는 공개 API이며 응답 result가 배열입니다.
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _publicDio.get('/v7/members/$memberId/ratings');
    return parseRatingList(response.data);
  }

  // 등록·수정·삭제는 JWT를 붙이는 보호 Client를 사용합니다.
  Future<RatingDto> createRating(CreateRatingRequest request) async {
    final response = await _authDio.post('/v7/ratings', data: request.toJson());
    return parseRatingResult(response.data);
  }

  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final response = await _authDio.patch(
      '/v7/ratings/$ratingId',
      // PATCH는 전체 교체이므로 null comment도 명시적으로 전송합니다.
      data: {'score': score, 'comment': comment},
    );
    return parseRatingResult(response.data);
  }

  Future<void> deleteRating(int ratingId) async {
    final response = await _authDio.delete('/v7/ratings/$ratingId');
    // v7 삭제 성공은 result가 null인 HTTP 200입니다.
    if (response.statusCode != 200) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}

String writeErrorMessage(DioException error) {
  final code = apiErrorCode(error);
  switch (code) {
    case 'AUTH401_2':
    case 'AUTH401_3':
    case 'AUTH401_4':
      return '로그인이 만료됐어요. 다시 로그인해 주세요.';
    case 'RATING403_1':
      return '이 평점을 수정하거나 삭제할 권한이 없어요.';
    case 'RATING409_1':
      return '이미 이 영화에 평점을 등록했어요.';
    case 'RATING404_1':
      return '평점을 찾을 수 없어요. 목록을 새로고침해 주세요.';
  }

  final data = error.response?.data;

  final common = data is Map<String, dynamic>
      ? CommonResponse<Object?>.fromJson(data, (value) => value)
      : null;

  return common?.message ?? '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

bool shouldRefreshAfterRatingError(DioException error) {
  return apiErrorCode(error) == 'RATING404_1';
}

bool isExpiredAuthError(DioException error) {
  final code = apiErrorCode(error);
  return code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
}

bool isRatingConflictOrForbidden(DioException error) {
  final code = apiErrorCode(error);
  return code == 'RATING403_1' || code == 'RATING409_1';
}
