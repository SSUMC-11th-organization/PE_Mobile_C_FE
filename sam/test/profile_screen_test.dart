// 프로필 화면 테스트
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:movielog/screens/profile_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/widgets/stat_item.dart';

import 'helpers/fake_movielog.dart';

void main() {
  late AuthViewModel auth;

  setUp(() => auth = fakeAuthViewModel());

  Future<void> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/my',
      routes: [
        GoRoute(
          path: '/my',
          builder: (_, _) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'profile/edit',
              builder: (_, _) => const Scaffold(body: Text('프로필 수정 화면')),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: auth,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
  }

  TextButton editButton(WidgetTester tester) =>
      tester.widget<TextButton>(find.widgetWithText(TextButton, '프로필 수정'));

  testWidgets('shows the member, stats, ratings menu and genre chips', (
    tester,
  ) async {
    await tester.runAsync(() => signIn(auth));
    await pumpProfile(tester);

    expect(find.text('내 프로필'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('무비러버'), findsOneWidget);
    expect(find.text('movie@example.com'), findsOneWidget);

    expect(find.byType(StatItem), findsNWidgets(3));
    expect(find.text('342'), findsOneWidget);
    expect(find.text('내가 등록한 평점'), findsOneWidget);
    expect(find.byType(Chip), findsNWidgets(3));
    expect(find.text('드라마'), findsOneWidget);
  });

  testWidgets('프로필 수정 is disabled until the member is loaded', (tester) async {
    await pumpProfile(tester);

    expect(find.text('내 정보를 불러오는 중이에요'), findsOneWidget);
    expect(editButton(tester).onPressed, isNull);
  });

  testWidgets('프로필 수정 opens /my/profile/edit', (tester) async {
    await tester.runAsync(() => signIn(auth));
    await pumpProfile(tester);

    await tester.tap(find.text('프로필 수정'));
    await tester.pumpAndSettle();

    expect(find.text('프로필 수정 화면'), findsOneWidget);
  });

  testWidgets('로그아웃 signs out', (tester) async {
    await tester.runAsync(() => signIn(auth));
    await pumpProfile(tester);

    await tester.runAsync(() async {
      await tester.tap(find.text('로그아웃'));
      // logout()의 저장소 정리가 끝날 때까지 기다림
      while (auth.storageCleanupInProgress) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pump();

    expect(auth.status, AuthStatus.signedOut);
    expect(auth.sessionExpired, isFalse);
    expect(find.text('내 정보를 불러오는 중이에요'), findsOneWidget);
  });
}
