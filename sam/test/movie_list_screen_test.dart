// 영화 목록 화면 테스트
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/services/fake_movie_service.dart';
import 'package:movielog/services/genre_preference_store.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/movie_poster_card.dart';

void main() {
  setUp(() => const GenrePreferenceStore().clear());

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

  testWidgets('restores the last selected genre when the screen is rebuilt', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MovieListScreen()),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.widgetWithText(ChoiceChip, 'SF'));
    await tester.pump();

    // 다른 화면으로 갔다가 다시 영화 목록 화면을 만든다
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MovieListScreen()),
    );
    await tester.pump(const Duration(seconds: 1));

    final sfChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'SF'),
    );
    expect(sfChip.selected, isTrue);
    expect(find.byType(MoviePosterCard), findsOneWidget);
    expect(find.text('우주의 끝에서'), findsOneWidget);
  });

  testWidgets('falls back to all genres when the saved genre is missing', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const GenrePreferenceStore().save('없는 장르');

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MovieListScreen()),
    );
    await tester.pump(const Duration(seconds: 1));

    final allChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '전체'),
    );
    expect(allChip.selected, isTrue);
    expect(find.byType(MoviePosterCard), findsNWidgets(2));
  });
}
