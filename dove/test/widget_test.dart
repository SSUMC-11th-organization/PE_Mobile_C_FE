import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/main.dart';
import 'package:movielog/screen/signup_screen.dart';

void main() {
  testWidgets('앱 실행 시 회원가입 화면이 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(SignupScreen), findsOneWidget);
  });
}
