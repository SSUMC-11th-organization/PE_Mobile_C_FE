// 시작 화면 테스트
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/main.dart';

void main() {
  testWidgets('Start screen shows title and start button', (
    WidgetTester tester,
  ) async {
    // 서비스·ViewModel Provider는 lazy라 시작 화면에서는 TMDB를 호출하지 않음
    await tester.pumpWidget(const MovieLogApp());

    expect(find.text('영화의 순간을\n기록하세요'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
  });
}
