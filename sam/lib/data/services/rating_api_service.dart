// 회원 평점 서비스: 조회(v5) + 등록·수정·삭제(v6)
import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

class RatingApiService {
  RatingApiService(this._dio);
  final Dio _dio;

  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v5/members/$memberId/ratings');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    final response = await _dio.post(
      '/v6/members/$memberId/ratings',
      data: request.toJson(),
    );
    // 201을 성공으로 처리합니다. result의 숫자/null 계약은 확인 전 파싱하지 않습니다.
    if (response.statusCode != 201) {
      throw StateError('예상하지 못한 등록 응답: ${response.statusCode}');
    }
  }

  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    await _dio.patch(
      '/v6/members/$memberId/ratings/$ratingId',
      data: {'score': score, 'comment': comment},
    );
  }

  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final response = await _dio.delete(
      '/v6/members/$memberId/ratings/$ratingId',
    );
    if (response.statusCode != 204) {
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
    403 => '내가 등록한 평점만 수정·삭제할 수 있어요. 목록을 다시 불러왔어요.',
    404 => '이미 삭제되었거나 없는 평점이에요. 목록을 다시 불러왔어요.',
    409 => serverMessage ?? '이미 평점을 등록한 영화예요.',
    _ => writeErrorMessage(error),
  };
}

String? _serverMessage(DioException error) {
  final data = error.response?.data;
  final message = data is Map<String, dynamic> ? data['message'] : null;
  return message is String && message.trim().isNotEmpty ? message : null;
}

bool shouldRefreshAfterRatingError(DioException error) {
  final data = error.response?.data;
  final code = data is Map<String, dynamic> ? data['code'] : null;
  final status = error.response?.statusCode;
  // 403·404는 화면에 남은 목록이 서버 상태와 어긋났다는 뜻이므로 다시 조회해서 맞춥니다.
  return code == 'COMMON403' ||
      code == 'COMMON404' ||
      status == 403 ||
      status == 404;
}
