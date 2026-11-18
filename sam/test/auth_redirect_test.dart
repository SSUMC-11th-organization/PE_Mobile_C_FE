// 로그인 상태별 라우터 redirect 테스트
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/auth_view_model.dart';

void main() {
  test('initializing and retryRequired keep the splash at /start', () {
    for (final status in [AuthStatus.initializing, AuthStatus.retryRequired]) {
      expect(authRedirect(status, '/start'), isNull);
      expect(authRedirect(status, '/home'), '/start');
      expect(authRedirect(status, '/login'), '/start');
    }
  });

  test('signedOut and authenticating allow only public paths', () {
    for (final status in [AuthStatus.signedOut, AuthStatus.authenticating]) {
      expect(authRedirect(status, '/login'), isNull);
      expect(authRedirect(status, '/register'), isNull);
      expect(authRedirect(status, '/home'), '/login');
      expect(authRedirect(status, '/start'), '/login');
      expect(authRedirect(status, '/my/ratings'), '/login');
    }
  });

  test('signedIn leaves splash and auth screens for /home', () {
    expect(authRedirect(AuthStatus.signedIn, '/start'), '/home');
    expect(authRedirect(AuthStatus.signedIn, '/login'), '/home');
    expect(authRedirect(AuthStatus.signedIn, '/register'), '/home');
    expect(authRedirect(AuthStatus.signedIn, '/movies'), isNull);
    expect(authRedirect(AuthStatus.signedIn, '/movies/550'), isNull);
  });
}
