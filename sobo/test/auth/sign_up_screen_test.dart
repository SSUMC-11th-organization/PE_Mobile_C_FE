import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';

void main() {
  testWidgets('회원가입 Form이 표시된다', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('회원가입'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('필수 약관에 동의합니다'), findsOneWidget);
    expect(find.text('가입하기'), findsOneWidget);
  });

  testWidgets('모든 조건을 입력하면 가입 버튼이 활성화된다', (tester) async {
    await tester.pumpWidget(const MyApp());

    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), '무비러버');
    await tester.enterText(fields.at(1), 'sobo@example.com');
    await tester.enterText(fields.at(2), '12345678');

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '가입하기'),
    );

    expect(button.onPressed, isNotNull);
  });
}
