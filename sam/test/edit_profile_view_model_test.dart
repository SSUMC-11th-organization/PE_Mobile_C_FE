// 프로필(닉네임) 수정 ViewModel 테스트
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/token_storage.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/edit_profile_view_model.dart';

import 'helpers/fake_movielog.dart';

class _MemoryTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<void> saveAccessToken(String token) async => this.token = token;

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<void> deleteAccessToken() async => token = null;
}

Map<String, dynamic> _member(String nickname) => {
  'isSuccess': true,
  'code': 'COMMON200',
  'message': '성공',
  'result': {
    'email': 'movie@example.com',
    'nickname': nickname,
    'createdAt': '2026-11-18T10:30:00',
  },
};

Map<String, dynamic> _fail(String code, [String message = '실패']) => {
  'isSuccess': false,
  'code': code,
  'message': message,
};

void main() {
  late FakeMovieLogAdapter server;
  late _MemoryTokenStorage storage;
  late AuthViewModel auth;
  late EditProfileViewModel viewModel;

  // PATCH /v7/members/me 응답 (테스트마다 바꿔 끼움)
  var patch = () => (200, _member('새닉네임'));

  setUp(() async {
    patch = () => (200, _member('새닉네임'));
    server = FakeMovieLogAdapter((options) {
      if (options.path == '/v7/auth/login') {
        return (
          200,
          {
            'isSuccess': true,
            'code': 'COMMON200',
            'message': '로그인 성공',
            'result': {'nickname': '무비러버', 'accessToken': 'token-abc'},
          },
        );
      }
      return options.method == 'PATCH' ? patch() : (200, _member('무비러버'));
    });
    storage = _MemoryTokenStorage();
    final dio = fakeDio(server);
    final memberApi = MemberApiService(dio);
    auth = AuthViewModel(AuthApiService(dio), memberApi, storage);
    await auth.login('movie@example.com', 'pw1234');
    await auth.loadMember();
    viewModel = EditProfileViewModel(memberApi, auth);
  });

  List<RequestOptions> patchRequests() =>
      server.requests.where((r) => r.method == 'PATCH').toList();

  test('validateNickname allows only 2~12 characters after trimming', () {
    expect(viewModel.validateNickname(' 가 '), '닉네임은 2~12자로 입력해 주세요.');
    expect(viewModel.validateNickname('가' * 13), '닉네임은 2~12자로 입력해 주세요.');
    expect(viewModel.validateNickname('  무비  '), isNull);
    expect(viewModel.validateNickname('가' * 12), isNull);
  });

  test('an invalid nickname shows the field error without a request', () async {
    expect(await viewModel.save('가'), isFalse);

    expect(viewModel.nicknameError, '닉네임은 2~12자로 입력해 주세요.');
    expect(patchRequests(), isEmpty);
  });

  test('the same nickname succeeds without a request', () async {
    expect(await viewModel.save('  무비러버 '), isTrue);

    expect(viewModel.status, EditProfileStatus.success);
    expect(patchRequests(), isEmpty);
  });

  test('a new nickname is sent and replaces the member in auth', () async {
    final future = viewModel.save(' 새닉네임 ');
    expect(viewModel.status, EditProfileStatus.saving);

    expect(await future, isTrue);
    expect(patchRequests().single.data, {'nickname': '새닉네임'});
    expect(viewModel.status, EditProfileStatus.success);
    expect(auth.member?.nickname, '새닉네임');
  });

  test('MEMBER409_1 shows a duplicate error under the field', () async {
    patch = () => (409, _fail('MEMBER409_1'));

    expect(await viewModel.save('중복닉네임'), isFalse);

    expect(viewModel.status, EditProfileStatus.failure);
    expect(viewModel.nicknameError, '이미 사용 중인 닉네임이에요.');
    expect(auth.member?.nickname, '무비러버');
  });

  test('COMMON400 shows the server message under the field', () async {
    patch = () => (400, _fail('COMMON400', '닉네임에 공백을 넣을 수 없어요.'));

    await viewModel.save('새 닉네임');

    expect(viewModel.nicknameError, '닉네임에 공백을 넣을 수 없어요.');
  });

  test('MEMBER404_1 shows a snackbar message', () async {
    patch = () => (404, _fail('MEMBER404_1'));

    await viewModel.save('새닉네임');

    expect(viewModel.message, '회원 정보를 찾을 수 없어요.');
    expect(viewModel.nicknameError, isNull);
  });

  test('an expired session signs out through auth', () async {
    patch = () => (401, _fail('AUTH401_3'));

    expect(await viewModel.save('새닉네임'), isFalse);

    expect(auth.status, AuthStatus.signedOut);
    expect(auth.sessionExpired, isTrue);
    expect(storage.token, isNull);
  });

  test('other failures keep the session and show a network message', () async {
    patch = () => (500, _fail('COMMON500'));

    await viewModel.save('새닉네임');

    expect(viewModel.message, '네트워크 상태를 확인하고 다시 시도해 주세요.');
    expect(auth.status, AuthStatus.signedIn);
  });

  test('a second save while saving is ignored', () async {
    final first = viewModel.save('새닉네임');

    expect(await viewModel.save('또다른닉네임'), isFalse);
    await first;

    expect(patchRequests(), hasLength(1));
  });
}
