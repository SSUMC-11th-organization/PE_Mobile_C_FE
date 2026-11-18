import 'package:dio/dio.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/models/movie_record_models.dart';

// 평점과 즐겨찾기를 서버에서 한 트랜잭션으로 저장합니다. 보호용 Dio(JWT)를 주입받습니다.
class MovieRecordApiService {
  MovieRecordApiService(this._dio);

  final Dio _dio;

  // 이 요청은 자동으로 다시 보내지 않습니다(중복 저장 방지).
  Future<MovieRecordResponseDto> createMovieRecord(
    CreateMovieRecordRequest request,
  ) async {
    final response = await _dio.post(
      '/v8/movie-records',
      data: request.toJson(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('movie-records 응답 형식이 올바르지 않습니다.');
    }
    final body = CommonResponse<MovieRecordResponseDto>.fromJson(
      data,
      MovieRecordResponseDto.fromJson,
    );
    final result = body.result;
    if (result == null) throw StateError('movie-records result가 없습니다.');
    return result;
  }
}
