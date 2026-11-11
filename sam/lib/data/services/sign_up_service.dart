// 회원가입 서비스: 닉네임·이메일 중복 확인(v5) + 회원가입 POST(v6)
import 'package:dio/dio.dart';

import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';

class SignUpService {
  SignUpService(this._dio);
  final Dio _dio;

  Future<bool> checkNickname(String nickname) async {
    final encoded = Uri.encodeComponent(nickname.trim());
    final response = await _dio.get('/v5/members/nickname/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  Future<bool> checkEmail(String email) async {
    final encoded = Uri.encodeComponent(email.trim());
    final response = await _dio.get('/v5/members/email/$encoded');
    return CheckResult.fromJson(response.data as Map<String, dynamic>)
        .available;
  }

  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _dio.post('/v6/members', data: request.toJson());

    return CommonResponse<SignUpResult>.fromJson(
      response.data as Map<String, dynamic>,
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
  }
}

// 실패 응답 본문(CommonResponse)의 message를 사용자 문구로 사용합니다.
String writeSignUpErrorMessage(DioException error) {
  const fallback = '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.';
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) return fallback;
  try {
    final common = CommonResponse<Object?>.fromJson(data, (value) => value);
    return common.message;
  } on TypeError {
    // 본문이 공통 응답 형식이 아니면 기본 문구를 씁니다.
    return fallback;
  }
}
