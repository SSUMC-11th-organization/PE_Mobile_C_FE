// 회원 평점 서비스: 공개 조회(publicDio) + 등록·수정·삭제(authDio, v7)
import 'package:dio/dio.dart';

import '../../core/network/api_error.dart';
import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

// W6 RatingDto/W7 CommonResponse를 재사용합니다.
RatingDto parseRatingResult(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw StateError('평점 응답 형식이 올바르지 않습니다.');
  }
  final common = CommonResponse<RatingDto>.fromJson(
    data,
    (value) => RatingDto.fromJson(value as Map<String, dynamic>),
  );
  final rating = common.result;
  if (rating == null) throw StateError('평점 result가 없습니다.');
  return rating;
}

List<RatingDto> parseRatingList(Object? data) {
  if (data is! List) throw StateError('평점 목록 응답은 배열이어야 합니다.');
  return data
      .map((value) => RatingDto.fromJson(value as Map<String, dynamic>))
      .toList();
}

class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);
  final Dio _publicDio;
  final Dio _authDio;

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _publicDio.get('/v7/members/$memberId/ratings');
    return parseRatingList(response.data); // 공개 조회: 직접 배열, 토큰 없음
  }

  Future<RatingDto> createRating(CreateRatingRequest request) async {
    final response = await _authDio.post('/v7/ratings', data: request.toJson());
    return parseRatingResult(response.data);
  }

  // PATCH는 부분 수정이 아니라 전체 교체입니다.
  // comment를 생략하면 서버에 null로 전달되어 기존 후기가 지워집니다.
  // Dialog를 열 때 기존 score·comment를 채워서 항상 두 값을 함께 보내야 합니다.
  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final response = await _authDio.patch(
      '/v7/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
    return parseRatingResult(response.data);
  }

  Future<void> deleteRating(int ratingId) async {
    final response = await _authDio.delete('/v7/ratings/$ratingId');
    if (response.statusCode != 200) throw StateError('예상하지 못한 삭제 응답');
  }
}

String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}

// 등록·수정·삭제 실패 응답(CommonResponse)의 message를 사용자 문구로 사용합니다.
String writeErrorMessage(DioException error) {
  const fallback = '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return fallback;
  try {
    return CommonResponse<Object?>.fromJson(data, (value) => value).message;
  } on TypeError {
    // 본문이 공통 응답 형식이 아니면 기본 문구를 씁니다.
    return fallback;
  }
}

// 평점 등록·수정·삭제 실패를 400/403/404/409로 구별한 사용자 문구
String writeRatingErrorMessage(DioException error) {
  final serverMessage = _serverMessage(error);
  return switch (error.response?.statusCode) {
    400 => serverMessage ?? '입력한 평점 정보를 다시 확인해 주세요.',
    401 => '로그인이 만료됐어요. 다시 로그인해 주세요.',
    403 => '내가 등록한 평점만 수정·삭제할 수 있어요. 목록을 다시 불러왔어요.',
    404 => '이미 삭제되었거나 없는 평점이에요. 목록을 다시 불러왔어요.',
    409 => serverMessage ?? '이미 평점을 등록한 영화예요.',
    _ => writeErrorMessage(error),
  };
}

// 빈 문자열이면 기본 문구를 쓰도록 null로 취급
String? _serverMessage(DioException error) {
  final message = apiErrorMessage(error);
  return message != null && message.trim().isNotEmpty ? message : null;
}

bool shouldRefreshAfterRatingError(DioException error) {
  final code = apiErrorCode(error);
  final status = error.response?.statusCode;
  // 403·404는 화면에 남은 목록이 서버 상태와 어긋났다는 뜻이므로 다시 조회해서 맞춥니다.
  return code == 'COMMON403' ||
      code == 'COMMON404' ||
      status == 403 ||
      status == 404;
}
