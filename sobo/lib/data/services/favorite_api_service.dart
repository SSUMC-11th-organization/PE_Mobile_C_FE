import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/favorite_check_dto.dart';
import '../models/favorite_response_dto.dart';

class FavoriteApiService {
  FavoriteApiService(this._dio);

  final Dio _dio;

  Future<FavoriteResponseDto> addFavorite({required int movieId}) async {
    final response = await _dio.post(
      '/v8/favorites',
      data: {'movieId': movieId},
    );
    final common = CommonResponse<FavoriteResponseDto>.fromJson(
      response.data as Map<String, dynamic>,
      FavoriteResponseDto.fromJson,
    );
    final result = common.result;
    if (result == null) throw StateError('즐겨찾기 등록 result가 없습니다.');
    return result;
  }

  Future<List<FavoriteResponseDto>> fetchMyFavorites() async {
    final response = await _dio.get('/v8/favorites');
    final common = CommonResponse<List<FavoriteResponseDto>>.fromJson(
      response.data as Map<String, dynamic>,
      (value) {
        if (value is! List) {
          throw const FormatException('즐겨찾기 목록 result는 배열이어야 합니다.');
        }
        return value.map(FavoriteResponseDto.fromJson).toList();
      },
    );
    return common.result ?? const [];
  }

  Future<FavoriteCheckDto> checkFavorite({required int movieId}) async {
    final response = await _dio.get('/v8/favorites/$movieId');
    final common = CommonResponse<FavoriteCheckDto>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => FavoriteCheckDto.fromJson(value, movieId: movieId),
    );
    final result = common.result;
    if (result == null) throw StateError('즐겨찾기 여부 result가 없습니다.');
    return result;
  }

  Future<void> deleteFavorite({required int movieId}) async {
    final response = await _dio.delete('/v8/favorites/$movieId');
    if (response.statusCode != 200) {
      throw StateError('예상하지 못한 즐겨찾기 삭제 응답: ${response.statusCode}');
    }
  }
}
