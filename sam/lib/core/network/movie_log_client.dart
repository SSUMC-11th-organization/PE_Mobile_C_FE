// MovieLog 학습용 서버(v5 API) 요청용 Dio
import 'package:dio/dio.dart';

Dio createMovieLogClient() {
  return Dio(
    BaseOptions(
      baseUrl: 'https://workbook.devnoco.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
}
