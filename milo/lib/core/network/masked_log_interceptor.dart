import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class MaskedLogInterceptor extends Interceptor {
  static const _secretKeys = {
    'password',
    'accessToken',
    'refreshToken',
    'token',
    'authorization',
    'email',
    'nickname',
  };

  dynamic _mask(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, v) => MapEntry(
          key,
          _secretKeys.contains(key.toString()) ? '***' : _mask(v),
        ),
      );
    }
    if (value is List) return value.map(_mask).toList();
    return value;
  }

  Map<String, dynamic> _maskHeaders(Map<String, dynamic> headers) => {
    for (final e in headers.entries)
      e.key: e.key.toLowerCase() == 'authorization' ? 'Bearer ***' : e.value,
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('➡️ ${options.method} ${options.uri.path}');
      debugPrint('   headers: ${_maskHeaders(options.headers)}');
      if (options.data != null) debugPrint('   body: ${_mask(options.data)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '✅ ${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.uri.path}',
      );
      debugPrint('   body: ${_mask(response.data)}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '❌ ${err.response?.statusCode ?? err.type.name} '
        '${err.requestOptions.method} ${err.requestOptions.uri.path}',
      );
      if (err.response?.data != null) {
        debugPrint('   body: ${_mask(err.response?.data)}');
      }
    }
    handler.next(err);
  }
}
