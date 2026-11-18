// 로그인 서비스 테스트
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/login_models.dart';
import 'package:movielog/data/services/auth_api_service.dart';

import 'helpers/fake_movielog.dart';

void main() {
  const request = LoginRequest(
    email: '  movie@example.com ',
    password: 'pw1234',
  );

  test('posts trimmed credentials and returns the token', () async {
    final adapter = FakeMovieLogAdapter(
      (_) => (
        200,
        {
          'isSuccess': true,
          'code': 'COMMON200',
          'message': '로그인 성공',
          'result': {'nickname': '무비러버', 'accessToken': 'token-abc'},
        },
      ),
    );

    final result = await AuthApiService(fakeDio(adapter)).login(request);

    final sent = adapter.requests.single;
    expect(sent.method, 'POST');
    expect(sent.path, '/v7/auth/login');
    expect(sent.data, {'email': 'movie@example.com', 'password': 'pw1234'});
    expect(result.nickname, '무비러버');
    expect(result.accessToken, 'token-abc');
  });

  test('a success without result is a StateError', () async {
    final adapter = FakeMovieLogAdapter(
      (_) =>
          (200, {'isSuccess': true, 'code': 'COMMON200', 'message': '로그인 성공'}),
    );

    expect(
      AuthApiService(fakeDio(adapter)).login(request),
      throwsA(isA<StateError>()),
    );
  });

  test('a 401 is thrown as DioException with the server code', () async {
    final adapter = FakeMovieLogAdapter(
      (_) => (
        401,
        {
          'isSuccess': false,
          'code': 'AUTH401_1',
          'message': '이메일 또는 비밀번호가 올바르지 않습니다.',
        },
      ),
    );

    expect(
      AuthApiService(fakeDio(adapter)).login(request),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
  });
}
