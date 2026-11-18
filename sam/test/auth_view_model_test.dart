// 로그인 상태(AuthViewModel) 테스트
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/token_storage.dart';
import 'package:movielog/view_models/auth_view_model.dart';

import 'helpers/fake_movielog.dart';

class _MemoryTokenStorage implements TokenStorage {
  String? token;
  bool failOnRead = false;
  bool failOnSave = false;

  @override
  Future<void> saveAccessToken(String token) async {
    if (failOnSave) throw Exception('keychain locked');
    this.token = token;
  }

  @override
  Future<String?> readAccessToken() async {
    if (failOnRead) throw Exception('keychain locked');
    return token;
  }

  @override
  Future<void> deleteAccessToken() async => token = null;
}

Map<String, dynamic> _loginOk() => {
  'isSuccess': true,
  'code': 'COMMON200',
  'message': '로그인 성공',
  'result': {'nickname': '무비러버', 'accessToken': 'token-abc'},
};

Map<String, dynamic> _meOk() => {
  'isSuccess': true,
  'code': 'COMMON200',
  'message': '조회 성공',
  'result': {
    'email': 'movie@example.com',
    'nickname': '무비러버',
    'createdAt': '2026-11-18T10:30:00',
  },
};

Map<String, dynamic> _fail(String code) => {
  'isSuccess': false,
  'code': code,
  'message': '실패',
};

void main() {
  late FakeMovieLogAdapter server;
  late _MemoryTokenStorage storage;
  late AuthViewModel viewModel;

  // 경로별 응답 (테스트마다 바꿔 끼움)
  var login = () => (200, _loginOk());
  var me = () => (200, _meOk());

  setUp(() {
    login = () => (200, _loginOk());
    me = () => (200, _meOk());
    server = FakeMovieLogAdapter(
      (options) => options.path == '/v7/auth/login' ? login() : me(),
    );
    storage = _MemoryTokenStorage();
    final dio = fakeDio(server);
    viewModel = AuthViewModel(
      AuthApiService(dio),
      MemberApiService(dio),
      storage,
    );
  });

  int meRequests() =>
      server.requests.where((r) => r.path == '/v7/members/me').length;

  group('login', () {
    test('saves the token and becomes signedIn', () async {
      final future = viewModel.login('movie@example.com', 'pw1234');
      expect(viewModel.status, AuthStatus.authenticating);
      await future;

      expect(viewModel.status, AuthStatus.signedIn);
      expect(storage.token, 'token-abc');
      expect(viewModel.message, isNull);
      // 신규 로그인은 내 정보를 MainScreen.loadMember()에서 따로 불러옴
      expect(viewModel.member, isNull);
      expect(meRequests(), 0);
    });

    test('AUTH401_1 asks to check the email and password', () async {
      login = () => (401, _fail('AUTH401_1'));

      await viewModel.login('movie@example.com', 'wrong');

      expect(viewModel.status, AuthStatus.signedOut);
      expect(viewModel.message, '이메일 또는 비밀번호를 확인해 주세요.');
      expect(storage.token, isNull);
    });

    test('other server failures show a generic message', () async {
      login = () => (500, _fail('COMMON500'));

      await viewModel.login('movie@example.com', 'pw1234');

      expect(viewModel.status, AuthStatus.signedOut);
      expect(viewModel.message, '로그인 요청에 실패했어요. 잠시 후 다시 시도해 주세요.');
    });

    test('a token save failure stays signedOut', () async {
      storage.failOnSave = true;

      await viewModel.login('movie@example.com', 'pw1234');

      expect(viewModel.status, AuthStatus.signedOut);
      expect(viewModel.message, '로그인 정보를 안전하게 저장하지 못했어요.');
    });
  });

  group('restoreSession', () {
    test(
      'no saved token becomes signedOut without calling the server',
      () async {
        await viewModel.restoreSession();

        expect(viewModel.status, AuthStatus.signedOut);
        expect(server.requests, isEmpty);
      },
    );

    test('a saved token is verified with GET me before signedIn', () async {
      storage.token = 'token-abc';

      final future = viewModel.restoreSession();
      expect(viewModel.status, AuthStatus.initializing);
      await future;

      expect(viewModel.status, AuthStatus.signedIn);
      expect(viewModel.member?.nickname, '무비러버');
      expect(viewModel.memberStatus, MemberLoadStatus.success);
      expect(meRequests(), 1);
    });

    for (final code in ['AUTH401_2', 'AUTH401_3', 'AUTH401_4']) {
      test('$code clears the token as an expired session', () async {
        storage.token = 'expired-token';
        me = () => (401, _fail(code));

        await viewModel.restoreSession();

        expect(viewModel.status, AuthStatus.signedOut);
        expect(viewModel.sessionExpired, isTrue);
        expect(storage.token, isNull);
      });
    }

    test('a network failure asks to retry and keeps the token', () async {
      storage.token = 'token-abc';
      me = () => (500, _fail('COMMON500'));

      await viewModel.restoreSession();

      expect(viewModel.status, AuthStatus.retryRequired);
      expect(viewModel.message, '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.');
      expect(storage.token, 'token-abc');
    });

    test('a storage read failure asks to retry', () async {
      storage.failOnRead = true;

      await viewModel.restoreSession();

      expect(viewModel.status, AuthStatus.retryRequired);
      expect(viewModel.message, '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.');
    });
  });

  group('loadMember', () {
    setUp(() async => viewModel.login('movie@example.com', 'pw1234'));

    test('loads the member once and refetches only with force', () async {
      await viewModel.loadMember();
      expect(viewModel.member?.email, 'movie@example.com');
      expect(viewModel.memberStatus, MemberLoadStatus.success);

      await viewModel.loadMember();
      expect(meRequests(), 1);

      await viewModel.loadMember(force: true);
      expect(meRequests(), 2);
    });

    test('does nothing when not signed in', () async {
      final signedOut = AuthViewModel(
        AuthApiService(fakeDio(server)),
        MemberApiService(fakeDio(server)),
        _MemoryTokenStorage(),
      );

      await signedOut.loadMember();

      expect(signedOut.memberStatus, MemberLoadStatus.idle);
      expect(meRequests(), 0);
    });

    test('an expired token signs out and deletes the token', () async {
      me = () => (401, _fail('AUTH401_3'));

      await viewModel.loadMember();

      expect(viewModel.status, AuthStatus.signedOut);
      expect(viewModel.sessionExpired, isTrue);
      expect(storage.token, isNull);
    });

    test('a network failure keeps the session and allows a retry', () async {
      me = () => (500, _fail('COMMON500'));

      await viewModel.loadMember();

      expect(viewModel.status, AuthStatus.signedIn);
      expect(viewModel.memberStatus, MemberLoadStatus.error);
      expect(viewModel.message, '내 정보를 불러오지 못했어요.');

      me = () => (200, _meOk());
      await viewModel.loadMember();

      expect(viewModel.memberStatus, MemberLoadStatus.success);
    });
  });

  group('updateMember and expireSession', () {
    final updated = MemberInfo(
      email: 'movie@example.com',
      nickname: '새닉네임',
      createdAt: DateTime(2026, 11, 18),
    );

    test('updateMember replaces the member without calling GET me', () async {
      await viewModel.login('movie@example.com', 'pw1234');
      var notified = 0;
      viewModel.addListener(() => notified++);

      viewModel.updateMember(updated);

      expect(viewModel.member?.nickname, '새닉네임');
      expect(notified, 1);
      expect(meRequests(), 0);
    });

    test('updateMember is ignored when not signed in', () {
      viewModel.updateMember(updated);

      expect(viewModel.member, isNull);
    });

    test(
      'expireSession signs out, deletes the token and marks expired',
      () async {
        await viewModel.login('movie@example.com', 'pw1234');
        await viewModel.loadMember();

        await viewModel.expireSession();

        expect(viewModel.status, AuthStatus.signedOut);
        expect(viewModel.sessionExpired, isTrue);
        expect(viewModel.member, isNull);
        expect(storage.token, isNull);
      },
    );

    test('consumeSessionExpired clears the flag after it was shown', () async {
      await viewModel.login('movie@example.com', 'pw1234');
      await viewModel.expireSession();
      expect(viewModel.sessionExpired, isTrue);

      viewModel.consumeSessionExpired();

      expect(viewModel.sessionExpired, isFalse);
      expect(viewModel.status, AuthStatus.signedOut);
    });

    test('logout clears the session without the expired message', () async {
      await viewModel.login('movie@example.com', 'pw1234');
      await viewModel.loadMember();

      await viewModel.logout();

      expect(viewModel.status, AuthStatus.signedOut);
      expect(viewModel.sessionExpired, isFalse);
      expect(viewModel.member, isNull);
      expect(storage.token, isNull);
    });
  });
}
