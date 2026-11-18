// 프로필(닉네임) 수정 화면 테스트
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/token_storage.dart';
import 'package:movielog/screens/edit_profile_screen.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/edit_profile_view_model.dart';
import 'package:movielog/widgets/labeled_text_field.dart';
import 'package:provider/provider.dart';

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

void main() {
  late FakeMovieLogAdapter server;
  late MemberApiService memberApi;
  late AuthViewModel auth;

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
    final dio = fakeDio(server);
    memberApi = MemberApiService(dio);
    auth = AuthViewModel(AuthApiService(dio), memberApi, _MemoryTokenStorage());
    await auth.login('movie@example.com', 'pw1234');
    await auth.loadMember();
  });

  // 마이페이지 → 프로필 수정으로 들어간 상태를 만듦 (저장 성공 시 pop 확인용)
  Future<void> pumpEditScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/my',
      routes: [
        GoRoute(
          path: '/my',
          builder: (context, state) => Scaffold(
            body: Text(context.watch<AuthViewModel>().member!.nickname),
          ),
          routes: [
            GoRoute(
              path: 'profile/edit',
              builder: (context, state) =>
                  ChangeNotifierProvider<EditProfileViewModel>(
                    create: (_) => EditProfileViewModel(memberApi, auth),
                    child: const EditProfileScreen(),
                  ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.push('/my/profile/edit');
    await tester.pumpAndSettle();
  }

  Finder fieldIn(String label) => find.descendant(
    of: find.widgetWithText(LabeledTextField, label),
    matching: find.byType(TextField),
  );
  Finder nicknameField() => fieldIn('닉네임');

  testWidgets('fills in the read-only email and the current nickname', (
    tester,
  ) async {
    await pumpEditScreen(tester);

    final emailField = tester.widget<TextField>(fieldIn('이메일 (변경할 수 없습니다)'));
    expect(emailField.enabled, isFalse);
    expect(find.text('movie@example.com'), findsOneWidget);
    expect(tester.widget<TextField>(nicknameField()).controller?.text, '무비러버');
  });

  testWidgets('saving goes back to My page with the new nickname', (
    tester,
  ) async {
    await pumpEditScreen(tester);

    await tester.enterText(nicknameField(), '새닉네임');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsNothing);
    expect(find.text('프로필을 수정했어요.'), findsOneWidget);
    expect(find.text('새닉네임'), findsOneWidget);
  });

  testWidgets('a duplicate nickname stays on the screen with a field error', (
    tester,
  ) async {
    patch = () =>
        (409, {'isSuccess': false, 'code': 'MEMBER409_1', 'message': '중복'});
    await pumpEditScreen(tester);

    await tester.enterText(nicknameField(), '중복닉네임');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.text('이미 사용 중인 닉네임이에요.'), findsOneWidget);
    expect(find.text('중복닉네임'), findsOneWidget); // 입력값 유지
  });

  testWidgets('a network failure shows a snackbar and stays', (tester) async {
    patch = () =>
        (500, {'isSuccess': false, 'code': 'COMMON500', 'message': '오류'});
    await pumpEditScreen(tester);

    await tester.enterText(nicknameField(), '새닉네임');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.text('네트워크 상태를 확인하고 다시 시도해 주세요.'), findsOneWidget);
  });

  testWidgets('the field and button are locked while saving', (tester) async {
    await pumpEditScreen(tester);
    server.gate = Completer<void>();

    await tester.enterText(nicknameField(), '새닉네임');
    await tester.tap(find.text('저장'));
    await tester.pump();

    expect(tester.widget<TextField>(nicknameField()).enabled, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    server.gate!.complete();
    await tester.pumpAndSettle();
  });
}
