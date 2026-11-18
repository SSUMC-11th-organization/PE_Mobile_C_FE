import 'package:dio/dio.dart';
import 'package:movielog/data/models/common_response.dart';

class LoginRequest {
  const LoginRequest({required this.email, required this.password});
  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
    'email': email.trim(),
    'password': password,
  };
}

class LoginResult {
  const LoginResult({required this.nickname, required this.accessToken});
  final String nickname;
  final String accessToken;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      nickname: json['nickname'] as String,
      accessToken: json['accessToken'] as String,
    );
  }
}

// lib/data/services/auth_api_service.dart — 공개 Dio와 W7 CommonResponse를 사용합니다.
class AuthApiService {
  AuthApiService(this._dio);
  final Dio _dio;

  Future<LoginResult> login(LoginRequest request) async {
    final response = await _dio.post('/v8/auth/login', data: request.toJson());
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('로그인 응답 형식이 올바르지 않습니다.');
    }
    final common = CommonResponse<LoginResult>.fromJson(
      data,
      (value) => LoginResult.fromJson(value as Map<String, dynamic>),
    );
    final result = common.result;
    if (result == null) throw StateError('로그인 result가 없습니다.');
    return result;
  }
}
