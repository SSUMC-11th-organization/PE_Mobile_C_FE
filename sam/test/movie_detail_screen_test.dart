// 영화 상세 화면 테스트
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:movielog/screens/home_screen.dart';
import 'package:movielog/screens/movie_detail_screen.dart';
import 'package:movielog/widgets/movie_card.dart';
import 'package:movielog/widgets/movie_rating_input.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/movies/:movieId',
      builder: (context, state) => MovieDetailScreen(
        movieId: int.tryParse(state.pathParameters['movieId'] ?? ''),
      ),
    ),
  ],
);

void main() {
  testWidgets('tapping a movie card opens its detail screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));

    await tester.tap(find.byType(MovieCard));
    await tester.pumpAndSettle();

    expect(find.byType(MovieDetailScreen), findsOneWidget);
    expect(find.text('Cinema Archive'), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsOneWidget);
    expect(find.text('2024 • 드라마'), findsOneWidget);
  });

  testWidgets('shows a message for an unknown movie id', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MovieDetailScreen(movieId: 999)),
    );

    expect(find.text('영화를 찾을 수 없어요'), findsOneWidget);
  });

  testWidgets('shows the average rating as a read-only indicator', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MovieDetailScreen(movieId: 1)),
    );

    await tester.scrollUntilVisible(find.byType(RatingBarIndicator), 200);

    final indicator = tester.widget<RatingBarIndicator>(
      find.byType(RatingBarIndicator),
    );
    expect(indicator.rating, 4.5);
    expect(find.text('4.5'), findsOneWidget);
  });

  testWidgets('toggles favorite with a snackbar and icon change', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MovieDetailScreen(movieId: 1)),
    );

    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

    await tester.tap(find.text('즐겨찾기'));
    await tester.pump();
    expect(find.text('즐겨찾기에 추가했어요'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);

    await tester.tap(find.text('즐겨찾기'));
    await tester.pump();
    expect(find.text('즐겨찾기에서 삭제했어요'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
  });

  testWidgets('opens the rating dialog and submits a rating', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MovieDetailScreen(movieId: 1)),
    );

    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(MovieRatingInput), findsOneWidget);

    await tester.tap(find.text('등록'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('3.0점을 남겼어요'), findsOneWidget);
  });
}
