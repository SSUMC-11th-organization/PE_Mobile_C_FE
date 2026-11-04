import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/screens/auth/sign_up_screen.dart';

void main() {
  testWidgets('회원가입 입력란과 약관을 표시한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SignUpScreen(),
      ),
    );

    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('필수 약관에 동의합니다'), findsOneWidget);
    expect(find.text('가입하기'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '가입하기'),
    );

    expect(button.onPressed, isNull);
  });

  testWidgets('입력과 약관 동의 후 가입 버튼이 활성화된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SignUpScreen(),
      ),
    );

    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), '무비러버');
    await tester.enterText(fields.at(1), 'sobo@example.com');
    await tester.enterText(fields.at(2), '12345678');

    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '가입하기'),
    );

    expect(button.onPressed, isNotNull);
  });
}