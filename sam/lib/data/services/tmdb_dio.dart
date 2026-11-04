// TMDB 요청용 Dio 생성과 오류 메시지 변환
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'tmdb_config.dart';
import 'tmdb_logging_interceptor.dart';

Dio createTmdbClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Authorization': 'Bearer ${TmdbConfig.accessToken}',
        'accept': 'application/json',
      },
    ),
  );
  // 로그는 디버그 빌드에서만 출력
  if (kDebugMode) dio.interceptors.add(TmdbLoggingInterceptor());
  return dio;
}

// 서비스에서 던진 오류를 화면에 보여줄 문구로 바꿈
String tmdbErrorMessage(Object error) {
  if (error is! DioException) return '알 수 없는 오류가 발생했습니다.';

  if (error.response?.statusCode == 401) {
    return 'TMDB 인증에 실패했어요.\n.env의 토큰을 확인해 주세요.';
  }

  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => '네트워크 연결을 확인해 주세요.',
    _ => '영화를 불러오지 못했습니다.',
  };
}
