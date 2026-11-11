// 회원가입 화면 테스트
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:movielog/screens/signup_screen.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';

import 'helpers/fake_movielog.dart';

// 'taken'이 들어간 값만 중복으로 응답하는 서버
FakeMovieLogAdapter _server() => FakeMovieLogAdapter(
  (options) => (200, {'available': !options.path.contains('taken')}),
);

Widget _app(FakeMovieLogAdapter adapter) => MaterialApp(
  home: ChangeNotifierProvider(
    create: (_) => SignUpViewModel(SignUpService(fakeDio(adapter))),
    child: const SignupScreen(),
  ),
);

// 0: 닉네임 중복 확인, 1: 이메일 중복 확인 (로딩 중엔 글자가 사라지므로 타입으로 찾음)
Finder _checkButton(int index) => find.byType(MovieLogButton).at(index);

MovieLogButton _button(WidgetTester tester, Finder finder) =>
    tester.widget<MovieLogButton>(finder);

void main() {
  testWidgets('shows validation error for a short nickname', (tester) async {
    await tester.pumpWidget(_app(_server()));

    await tester.enterText(find.byType(TextFormField).first, 'a');
    await tester.pump();

    expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
    // 형식이 틀리면 중복 확인도 누를 수 없음
    expect(_button(tester, _checkButton(0)).onPressed, isNull);
  });

  testWidgets('nickname shows idle · checking · available · duplicated', (
    tester,
  ) async {
    final adapter = _server();
    await tester.pumpWidget(_app(adapter));
    final nicknameField = find.byType(TextFormField).first;

    // 확인 전
    await tester.enterText(nicknameField, '무비러버');
    await tester.pump();
    expect(_button(tester, _checkButton(0)).onPressed, isNotNull);
    expect(find.text('사용할 수 있는 닉네임입니다.'), findsNothing);

    // 통신 중
    adapter.gate = Completer<void>();
    await tester.tap(_checkButton(0));
    await tester.pump();
    expect(_button(tester, _checkButton(0)).isLoading, isTrue);

    // 사용 가능
    adapter.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('사용할 수 있는 닉네임입니다.'), findsOneWidget);

    // 닉네임을 바꾸면 결과가 사라지고(idle) 다시 확인할 수 있음 → 중복
    adapter.gate = null;
    await tester.enterText(nicknameField, 'taken');
    await tester.pump();
    expect(find.text('사용할 수 있는 닉네임입니다.'), findsNothing);
    await tester.tap(_checkButton(0));
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
  });

  testWidgets('a server failure shows a different message for email', (
    tester,
  ) async {
    final adapter = FakeMovieLogAdapter((_) => (500, {'message': 'error'}));
    await tester.pumpWidget(_app(adapter));

    await tester.enterText(find.byType(TextFormField).at(1), 'a@b.com');
    await tester.pump();
    await tester.tap(_checkButton(1));
    await tester.pumpAndSettle();

    expect(find.text('중복 확인에 실패했습니다. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('이미 사용 중인 이메일입니다.'), findsNothing);
    // 실패하면 다시 시도할 수 있음
    expect(_button(tester, _checkButton(1)).onPressed, isNotNull);
  });

  testWidgets('가입하기 is enabled only after both checks pass', (tester) async {
    await tester.pumpWidget(_app(_server()));
    MovieLogButton submit() =>
        _button(tester, find.widgetWithText(MovieLogButton, '가입하기'));

    await tester.enterText(find.byType(TextFormField).at(0), '무비러버');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'movie@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.tap(find.text('필수 약관에 동의합니다'));
    await tester.pump();
    expect(submit().onPressed, isNull);

    await tester.tap(_checkButton(0));
    await tester.pumpAndSettle();
    expect(submit().onPressed, isNull);

    await tester.tap(_checkButton(1));
    await tester.pumpAndSettle();
    expect(submit().onPressed, isNotNull);
  });

  testWidgets('re-validates the whole form when submitted via the keyboard', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_server()));

    await tester.enterText(find.byType(TextFormField).at(2), 'short');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('비밀번호는 8자 이상이어야 합니다.'), findsOneWidget);
    expect(find.byType(SignupScreen), findsOneWidget);
  });

  testWidgets('does not overflow when the keyboard covers the bottom inset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 400);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(_app(_server()));

    expect(tester.takeException(), isNull);
  });

  testWidgets('a successful sign-up saves the member and opens /movies', (
    tester,
  ) async {
    final adapter = FakeMovieLogAdapter(
      (options) => options.method == 'POST'
          ? (
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
            )
          : (200, {'available': true}),
    );
    final session = LearningMemberSession();
    final router = GoRouter(
      initialLocation: '/signup',
      routes: [
        GoRoute(
          path: '/signup',
          builder: (_, _) => ChangeNotifierProvider(
            create: (_) => SignUpViewModel(SignUpService(fakeDio(adapter))),
            child: const SignupScreen(),
          ),
        ),
        GoRoute(path: '/movies', builder: (_, _) => const Text('영화 목록')),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: session,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), '무비러버');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'movie@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.tap(find.text('필수 약관에 동의합니다'));
    await tester.tap(_checkButton(0));
    await tester.pumpAndSettle();
    await tester.tap(_checkButton(1));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('가입하기'));
    await tester.tap(find.text('가입하기'));
    await tester.pumpAndSettle();

    expect(session.memberId, 42);
    expect(find.text('영화 목록'), findsOneWidget);
  });
}
