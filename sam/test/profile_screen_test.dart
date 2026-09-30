// 프로필 화면 테스트
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/screens/profile_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/stat_item.dart';

void main() {
  testWidgets('shows the AppBar title, stats, and genre chips', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
    );

    expect(find.text('내 프로필'), findsOneWidget);
    expect(find.text('무비러버'), findsOneWidget);

    expect(find.byType(StatItem), findsNWidgets(3));
    expect(find.text('342'), findsOneWidget);
    expect(find.text('4.2'), findsOneWidget);
    expect(find.text('58'), findsOneWidget);

    expect(find.byType(Chip), findsNWidgets(3));
    expect(find.text('드라마'), findsOneWidget);

    expect(find.widgetWithText(TextButton, '프로필 수정'), findsOneWidget);
  });
}
