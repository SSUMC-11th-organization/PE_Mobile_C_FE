// 스플래시 화면 테스트
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/screens/splash_screen.dart';

void main() {
  testWidgets('shows a spinner while checking the login state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.text('영화의 순간을\n기록하세요'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);
  });

  testWidgets('shows the message and retries when onRetry is given', (
    tester,
  ) async {
    var retried = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(message: '네트워크 오류', onRetry: () => retried++),
      ),
    );

    expect(find.text('네트워크 오류'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('다시 시도'));
    expect(retried, 1);
  });

  testWidgets('falls back to the default message', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SplashScreen(onRetry: () {})));

    expect(find.text('로그인 상태를 확인하지 못했어요.'), findsOneWidget);
  });
}
