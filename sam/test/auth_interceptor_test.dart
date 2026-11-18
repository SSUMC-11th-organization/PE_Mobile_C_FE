// 토큰 인터셉터 테스트
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/data/services/token_storage.dart';

import 'helpers/fake_movielog.dart';

class _MemoryTokenStorage implements TokenStorage {
  _MemoryTokenStorage([this.token]);

  String? token;
  bool failOnRead = false;

  @override
  Future<void> saveAccessToken(String token) async => this.token = token;

  @override
  Future<String?> readAccessToken() async {
    if (failOnRead) throw Exception('keychain locked');
    return token;
  }

  @override
  Future<void> deleteAccessToken() async => token = null;
}

void main() {
  late FakeMovieLogAdapter adapter;
  late _MemoryTokenStorage storage;
  late Dio dio;

  setUp(() {
    adapter = FakeMovieLogAdapter((_) => (200, {}));
    storage = _MemoryTokenStorage('token-abc');
    dio = fakeDio(adapter, baseUrl: 'https://workbook.devnoco.com')
      ..interceptors.add(AuthInterceptor(storage));
  });

  String? sentAuthorization() =>
      adapter.requests.single.headers['Authorization'] as String?;

  for (final path in ['/v7/members/me', '/v7/ratings', '/v7/ratings/3']) {
    test('adds the Bearer token to $path', () async {
      await dio.get(path);

      expect(sentAuthorization(), 'Bearer token-abc');
    });
  }

  test('does not add the token to public paths', () async {
    await dio.post('/v7/auth/login');

    expect(sentAuthorization(), isNull);
  });

  test('does not add the token to other hosts', () async {
    await dio.get('https://api.themoviedb.org/v7/ratings');

    expect(sentAuthorization(), isNull);
  });

  test('drops a stale Authorization header when no token is saved', () async {
    storage.token = null;

    await dio.get(
      '/v7/members/me',
      options: Options(headers: {'Authorization': 'Bearer old-token'}),
    );

    expect(sentAuthorization(), isNull);
  });

  test('a storage failure rejects without calling the server', () async {
    storage.failOnRead = true;

    final error = await dio
        .get('/v7/members/me')
        .then<Object?>((_) => null, onError: (Object e) => e);

    expect(error, isA<DioException>());
    expect((error! as DioException).error, isA<StateError>());
    expect(adapter.requests, isEmpty);
  });

  test('only the auth client registers AuthInterceptor', () {
    final publicDio = createMovieLogClient();
    final authDio = createAuthMovieLogClient(storage);

    expect(publicDio.options.baseUrl, 'https://workbook.devnoco.com');
    expect(authDio.options.baseUrl, 'https://workbook.devnoco.com');
    expect(publicDio.interceptors.whereType<AuthInterceptor>(), isEmpty);
    expect(authDio.interceptors.whereType<AuthInterceptor>(), hasLength(1));
  });
}
