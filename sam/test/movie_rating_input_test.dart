// 별점 입력 위젯 테스트
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/widgets/movie_rating_input.dart';

void main() {
  testWidgets('reports the tapped rating', (WidgetTester tester) async {
    double? changed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MovieRatingInput(
              rating: 3,
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.star), findsNWidgets(5));

    // 마지막 별의 오른쪽 끝을 누르면 5점
    final lastStar = tester.getRect(find.byIcon(Icons.star).last);
    await tester.tapAt(lastStar.centerRight - const Offset(2, 0));
    await tester.pump();

    expect(changed, 5);
  });
}
