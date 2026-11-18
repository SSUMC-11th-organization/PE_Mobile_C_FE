// 로그인 화면 테스트
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/token_storage.dart';
import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/view_models/auth_view_model.dart';
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

void main() {
  late FakeMovieLogAdapter server;
  late _MemoryTokenStorage storage;
  late AuthViewModel auth;

  // POST /v7/auth/login 응답 (테스트마다 바꿔 끼움)
  var login = () => (
    200,
    <String, dynamic>{
      'isSuccess': true,
      'code': 'COMMON200',
      'message': '로그인 성공',
      'result': {'nickname': '무비러버', 'accessToken': 'token-abc'},
    },
  );

  setUp(() {
    login = () => (
      200,
      <String, dynamic>{
        'isSuccess': true,
        'code': 'COMMON200',
        'message': '로그인 성공',
        'result': {'nickname': '무비러버', 'accessToken': 'token-abc'},
      },
    );
    server = FakeMovieLogAdapter((_) => login());
    storage = _MemoryTokenStorage();
    final dio = fakeDio(server);
    auth = AuthViewModel(AuthApiService(dio), MemberApiService(dio), storage);
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(
          path: '/register',
          builder: (_, _) => const Scaffold(body: Text('회원가입 화면')),
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(
    of: find.widgetWithText(LabeledTextField, label),
    matching: find.byType(TextFormField),
  );
  Finder loginButton() => find.widgetWithText(ElevatedButton, '로그인');

  testWidgets('empty fields show validation errors without a request', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(loginButton());
    await tester.pump();

    expect(find.text('이메일을 입력해 주세요.'), findsOneWidget);
    expect(find.text('비밀번호를 입력해 주세요.'), findsOneWidget);
    expect(server.requests, isEmpty);
  });

  testWidgets('valid input logs in with the trimmed email', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(field('이메일'), '  movie@example.com ');
    await tester.enterText(field('비밀번호'), 'pw1234');
    await tester.tap(loginButton());
    await tester.pumpAndSettle();

    expect(server.requests.single.data, {
      'email': 'movie@example.com',
      'password': 'pw1234',
    });
    expect(auth.status, AuthStatus.signedIn);
    expect(storage.token, 'token-abc');
  });

  testWidgets('a wrong password shows the error message', (tester) async {
    login = () =>
        (401, {'isSuccess': false, 'code': 'AUTH401_1', 'message': '실패'});
    await pumpLogin(tester);

    await tester.enterText(field('이메일'), 'movie@example.com');
    await tester.enterText(field('비밀번호'), 'wrong');
    await tester.tap(loginButton());
    await tester.pumpAndSettle();

    expect(find.text('이메일 또는 비밀번호를 확인해 주세요.'), findsOneWidget);
    expect(auth.status, AuthStatus.signedOut);
  });

  testWidgets('inputs and buttons are locked while logging in', (tester) async {
    await pumpLogin(tester);
    server.gate = Completer<void>();

    await tester.enterText(field('이메일'), 'movie@example.com');
    await tester.enterText(field('비밀번호'), 'pw1234');
    await tester.tap(loginButton());
    await tester.pump();

    expect(tester.widget<TextFormField>(field('이메일')).enabled, isFalse);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, '회원가입'))
          .onPressed,
      isNull,
    );

    server.gate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('shows the session expired message once on entry', (
    tester,
  ) async {
    // 실제 비동기 요청은 fake async 밖에서 실행해야 끝남
    await tester.runAsync(() async {
      await auth.login('movie@example.com', 'pw1234');
      await auth.expireSession();
    });

    await pumpLogin(tester);

    expect(find.text('로그인이 만료됐어요. 다시 로그인해 주세요.'), findsOneWidget);
    expect(auth.sessionExpired, isFalse);
  });

  testWidgets('회원가입 opens /register', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();

    expect(find.text('회원가입 화면'), findsOneWidget);
  });
}
