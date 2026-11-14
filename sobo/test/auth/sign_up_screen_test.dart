import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/screens/auth/sign_up_screen.dart';
import 'package:movielog/services/sign_up_service.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

class FakeSignUpService extends SignUpService {
  FakeSignUpService() : super(Dio());
  int submissions = 0;

  @override
  Future<bool> checkNickname(String nickname) async => true;

  @override
  Future<bool> checkEmail(String email) async => true;

  @override
  Future<CommonResponse<SignUpResult>> signUp(CreateMemberRequest request) async {
    submissions++;
    return CommonResponse<SignUpResult>(
      isSuccess: true,
      code: 'COMMON201',
      message: '회원가입 성공',
      result: SignUpResult(memberId: 7, email: request.email, nickname: request.nickname),
    );
  }
}

void main() {
  Future<void> showSignUp(WidgetTester tester, FakeSignUpService service,
      LearningMemberSession session) async {
    final router = GoRouter(initialLocation: '/register', routes: [
      GoRoute(path: '/register', builder: (_, _) => const SignUpScreen()),
      GoRoute(path: '/movies', builder: (_, _) => const Scaffold(body: Text('영화 목록'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SignUpViewModel(service)),
        ChangeNotifierProvider.value(value: session),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('입력란과 중복 확인 버튼 두 개를 표시한다', (tester) async {
    final session = LearningMemberSession();
    addTearDown(session.dispose);
    await showSignUp(tester, FakeSignUpService(), session);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('중복 확인'), findsNWidgets(2));
    expect(find.text('가입하기'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '가입하기'));
    expect(button.onPressed, isNull);
  });

  testWidgets('중복 확인 전에는 가입 불가, 확인 후 실제 가입하고 회원 ID를 저장한다', (tester) async {
    final service = FakeSignUpService();
    final session = LearningMemberSession();
    addTearDown(session.dispose);
    await showSignUp(tester, service, session);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '무비러버');
    await tester.enterText(fields.at(1), 'sobo@example.com');
    await tester.enterText(fields.at(2), 'Umc1234!');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '가입하기')).onPressed, isNull);

    final checks = find.widgetWithText(ElevatedButton, '중복 확인');
    await tester.ensureVisible(checks.at(0));
    await tester.tap(checks.at(0));
    await tester.pumpAndSettle();
    await tester.ensureVisible(checks.at(1));
    await tester.tap(checks.at(1));
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(ElevatedButton, '가입하기');
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNotNull);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(service.submissions, 1);
    expect(session.memberId, 7);
    expect(find.text('영화 목록'), findsOneWidget);
  });
}
