// 회원가입 중복 확인 ViewModel 테스트
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

import 'helpers/fake_movielog.dart';

void main() {
  late FakeMovieLogAdapter adapter;
  late SignUpViewModel viewModel;

  // 'taken'이 들어간 값만 중복으로 응답
  (int, Object) server(options) =>
      (200, {'available': !options.path.contains('taken')});

  setUp(() {
    adapter = FakeMovieLogAdapter(server);
    viewModel = SignUpViewModel(SignUpService(fakeDio(adapter)));
  });

  test('available nickname → available with helper text', () async {
    viewModel.onNicknameChanged('무비러버');
    await viewModel.checkNickname('무비러버');

    expect(
      adapter.requests.single.path,
      '/v5/members/nickname/${Uri.encodeComponent('무비러버')}',
    );
    expect(viewModel.nicknameCheckStatus, CheckStatus.available);
    expect(viewModel.nicknameErrorText, isNull);
  });

  test('duplicated nickname shows a duplicate message', () async {
    viewModel.onNicknameChanged('taken');
    await viewModel.checkNickname('taken');

    expect(viewModel.nicknameCheckStatus, CheckStatus.duplicated);
    expect(viewModel.nicknameErrorText, '이미 사용 중인 닉네임입니다.');
  });

  test('server failure is shown differently from a duplicate', () async {
    adapter.route = (_) => (500, {'message': 'error'});
    viewModel.onEmailChanged('a@b.com');
    await viewModel.checkEmail('a@b.com');

    expect(viewModel.emailCheckStatus, CheckStatus.error);
    expect(viewModel.emailErrorText, '중복 확인에 실패했습니다. 다시 시도해 주세요.');
  });

  test('status is checking while the request is in flight', () async {
    adapter.gate = Completer<void>();
    viewModel.onNicknameChanged('무비러버');
    final pending = viewModel.checkNickname('무비러버');

    expect(viewModel.nicknameCheckStatus, CheckStatus.checking);
    adapter.gate!.complete();
    await pending;
    expect(viewModel.nicknameCheckStatus, CheckStatus.available);
  });

  test('changing the nickname resets the result to idle', () async {
    viewModel.onNicknameChanged('taken');
    await viewModel.checkNickname('taken');
    viewModel.onNicknameChanged('taken2');

    expect(viewModel.nicknameCheckStatus, CheckStatus.idle);
    expect(viewModel.nicknameErrorText, isNull);
  });

  test('a response for an old input is ignored', () async {
    adapter.gate = Completer<void>();
    viewModel.onNicknameChanged('taken');
    final pending = viewModel.checkNickname('taken');
    viewModel.onNicknameChanged('새닉네임');
    adapter.gate!.complete();
    await pending;

    expect(viewModel.nicknameCheckStatus, CheckStatus.idle);
  });

  test('typing a known duplicated nickname again shows duplicated', () async {
    viewModel.onNicknameChanged('taken');
    await viewModel.checkNickname('taken');
    viewModel.onNicknameChanged('taken2');
    viewModel.onNicknameChanged('taken');

    expect(viewModel.nicknameCheckStatus, CheckStatus.duplicated);
    expect(viewModel.canCheckNickname, isFalse);
    expect(adapter.requests, hasLength(1));
  });

  test('both checks must pass before signing up', () async {
    viewModel.onNicknameChanged('무비러버');
    await viewModel.checkNickname('무비러버');
    expect(viewModel.isDuplicateCheckPassed, isFalse);

    viewModel.onEmailChanged('movie@example.com');
    await viewModel.checkEmail('movie@example.com');
    expect(viewModel.isDuplicateCheckPassed, isTrue);
  });

  group('submit', () {
    const request = CreateMemberRequest(
      email: ' movie@example.com ',
      password: 'password123',
      nickname: '무비러버',
    );

    test('stores the created memberId on success', () async {
      adapter.route = (_) => (
        201,
        {
          'isSuccess': true,
          'code': 'COMMON201',
          'message': '가입 완료',
          'result': {
            'memberId': 42,
            'email': 'movie@example.com',
            'nickname': '무비러버',
          },
        },
      );

      final future = viewModel.submit(request);
      expect(viewModel.submitStatus, SubmitStatus.submitting);
      await future;

      final sent = adapter.requests.single;
      expect(sent.method, 'POST');
      expect(sent.path, '/v6/members');
      expect(sent.data, {
        'email': 'movie@example.com',
        'password': 'password123',
        'nickname': '무비러버',
      });
      expect(viewModel.submitStatus, SubmitStatus.success);
      expect(viewModel.createdMemberId, 42);
    });

    test('a 400 password message goes under the password field', () async {
      adapter.route = (_) => (
        400,
        {
          'isSuccess': false,
          'code': 'COMMON400',
          'message': '비밀번호는 영문과 숫자를 포함해야 합니다.',
        },
      );
      await viewModel.submit(request);

      expect(viewModel.submitStatus, SubmitStatus.error);
      expect(viewModel.passwordErrorText, '비밀번호는 영문과 숫자를 포함해야 합니다.');
      expect(viewModel.snackbarMessage, isNull);

      viewModel.onPasswordChanged();
      expect(viewModel.passwordErrorText, isNull);
    });

    test('other failures become a snackbar message', () async {
      adapter.route = (_) => (500, {'error': 'unexpected shape'});
      await viewModel.submit(request);

      expect(viewModel.submitStatus, SubmitStatus.error);
      expect(viewModel.snackbarMessage, '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.');
    });

    test('a success without memberId is reported, not ignored', () async {
      adapter.route = (_) =>
          (201, {'isSuccess': true, 'code': 'COMMON201', 'message': '가입 완료'});
      await viewModel.submit(request);

      expect(viewModel.submitStatus, SubmitStatus.error);
      expect(viewModel.createdMemberId, isNull);
      expect(viewModel.snackbarMessage, contains('가입 결과를 확인하지 못했습니다'));
    });
  });
}
