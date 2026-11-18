// 내 정보 서비스 — 토큰이 붙는 보호용 Dio(createAuthMovieLogClient)를 사용합니다.
import 'package:dio/dio.dart';

import '../models/member_info.dart';

class MemberApiService {
  MemberApiService(this._authDio);
  final Dio _authDio;

  Future<MemberInfo> fetchMe() async {
    final response = await _authDio.get('/v7/members/me');
    return parseMemberInfo(response.data);
  }

  Future<MemberInfo> updateNickname(String nickname) async {
    final response = await _authDio.patch(
      '/v7/members/me',
      data: {'nickname': nickname},
    );
    return parseMemberInfo(response.data);
  }
}
