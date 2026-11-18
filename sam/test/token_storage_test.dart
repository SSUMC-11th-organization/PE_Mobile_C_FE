// 토큰 저장소 테스트 (flutter_secure_storage 메모리 mock 사용)
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/token_storage.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('saves, reads and deletes the access token', () async {
    final storage = SecureTokenStorage(const FlutterSecureStorage());

    expect(await storage.readAccessToken(), isNull);

    await storage.saveAccessToken('token-abc');
    expect(await storage.readAccessToken(), 'token-abc');

    await storage.deleteAccessToken();
    expect(await storage.readAccessToken(), isNull);
  });

  test('reads a token saved under the movielog key', () async {
    FlutterSecureStorage.setMockInitialValues({
      'movielog.access_token': 'saved-token',
    });

    final storage = SecureTokenStorage(const FlutterSecureStorage());

    expect(await storage.readAccessToken(), 'saved-token');
  });
}
