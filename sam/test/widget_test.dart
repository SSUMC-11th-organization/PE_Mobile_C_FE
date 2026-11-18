// 앱 시작 흐름 테스트 (스플래시 → 세션 복원 → 로그인 화면)
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/screens/splash_screen.dart';

void main() {
  testWidgets('without a saved token the splash moves to the login screen', (
    WidgetTester tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(const MovieLogApp());

    // 첫 프레임: 토큰 확인 중이라 스플래시
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('영화의 순간을\n기록하세요'), findsOneWidget);

    // restoreSession() → 토큰 없음 → signedOut → redirect가 /login으로 보냄
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('MovieLog에 로그인'), findsOneWidget);
  });
}
