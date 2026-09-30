// 회원가입 화면 테스트
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/screens/signup_screen.dart';

void main() {
  testWidgets('shows validation error for a short nickname', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

    await tester.enterText(find.byType(TextFormField).first, 'a');
    await tester.pump();

    expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
  });

  testWidgets('가입하기 button is disabled until the form is valid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.enterText(find.byType(TextFormField).at(0), '무비러버');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'movie@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.tap(find.text('필수 약관에 동의합니다'));
    await tester.pump();

    final enabledButton = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(enabledButton.onPressed, isNotNull);
  });

  testWidgets('re-validates the whole form when submitted via the keyboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

    await tester.enterText(find.byType(TextFormField).at(2), 'short');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('비밀번호는 8자 이상이어야 합니다.'), findsOneWidget);
    expect(find.byType(SignupScreen), findsOneWidget);
  });

  testWidgets('does not overflow when the keyboard covers the bottom inset', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 400);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

    expect(tester.takeException(), isNull);
  });
}
