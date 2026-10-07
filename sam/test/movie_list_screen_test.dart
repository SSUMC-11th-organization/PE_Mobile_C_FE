// 영화 목록 화면 테스트
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/services/fake_movie_service.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/movie_poster_card.dart';

void main() {
  testWidgets('shows all movies and filters them by genre', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MovieListScreen()),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MoviePosterCard), findsNWidgets(2));
    expect(find.text('별빛 아래 우리'), findsOneWidget);
    expect(find.text('우주의 끝에서'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'SF'));
    await tester.pump();

    expect(find.byType(MoviePosterCard), findsOneWidget);
    expect(find.text('우주의 끝에서'), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsNothing);
  });

  testWidgets('shows empty message when there are no movies', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MovieListScreen(mode: MovieLoadMode.empty),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('표시할 영화가 없습니다.'), findsOneWidget);
    expect(find.byType(MoviePosterCard), findsNothing);
  });

  testWidgets('shows error message with retry when loading fails', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MovieListScreen(mode: MovieLoadMode.failure),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('영화를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
  });
}
