// 영화 목록 화면(Discover + 장르 필터) 테스트
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/models/movie.dart';
import 'package:movielog/screens/movie_detail_screen.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/widgets/movie_poster_card.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_tmdb.dart';

// 장르 API는 액션·드라마, Discover는 장르마다 다른 영화 한 페이지를 돌려줌
(int, Map<String, dynamic>) _respond(RequestOptions options) {
  if (options.path == '/genre/movie/list') return (200, genreListJson());

  return switch (options.queryParameters['with_genres']) {
    28 => (200, discoverPageJson([1])),
    18 => (200, discoverPageJson(const [])),
    _ => (200, discoverPageJson([1, 2, 3])),
  };
}

List<RequestOptions> _discoverRequests(FakeTmdbAdapter adapter) => adapter
    .requests
    .where((request) => request.path == '/discover/movie')
    .toList();

void main() {
  late FakeTmdbAdapter adapter;

  setUp(() {
    adapter = FakeTmdbAdapter(responder: _respond);
  });

  Future<void> pumpMovieList(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) =>
            MovieListViewModel(fakeTmdbService(adapter))..loadInitial(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MovieListScreen(),
        ),
      ),
    );
  }

  ChoiceChip chip(WidgetTester tester, String label) =>
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));

  testWidgets('builds genre chips from the genre API and shows movies', (
    tester,
  ) async {
    await pumpMovieList(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.widgetWithText(ChoiceChip, '전체'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '액션'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '드라마'), findsOneWidget);
    expect(chip(tester, '전체').selected, isTrue);
    expect(find.byType(MoviePosterCard), findsNWidgets(3));
  });

  testWidgets('"전체" does not send with_genres', (tester) async {
    await pumpMovieList(tester);
    await tester.pumpAndSettle();

    final request = _discoverRequests(adapter).single;
    expect(request.queryParameters.containsKey('with_genres'), isFalse);
    expect(request.queryParameters['page'], 1);
  });

  testWidgets('selecting a genre requests page 1 with with_genres', (
    tester,
  ) async {
    await pumpMovieList(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '액션'));
    await tester.pumpAndSettle();

    final request = _discoverRequests(adapter).last;
    expect(request.queryParameters['with_genres'], 28);
    expect(request.queryParameters['page'], 1);
    expect(chip(tester, '액션').selected, isTrue);
    expect(find.byType(MoviePosterCard), findsOneWidget);
  });

  testWidgets('genre chips are disabled while Discover is loading', (
    tester,
  ) async {
    await pumpMovieList(tester);
    await tester.pumpAndSettle();

    adapter.gate = Completer<void>();
    await tester.tap(find.widgetWithText(ChoiceChip, '액션'));
    await tester.pump();

    expect(chip(tester, '드라마').onSelected, isNull);
    await tester.tap(find.widgetWithText(ChoiceChip, '드라마'));
    await tester.pump();

    adapter.gate!.complete();
    await tester.pumpAndSettle();

    // 로딩 중 누른 '드라마'는 무시되고 '액션' 요청만 나감
    expect(_discoverRequests(adapter), hasLength(2));
    expect(chip(tester, '액션').selected, isTrue);
    expect(chip(tester, '드라마').onSelected, isNotNull);
  });

  testWidgets('shows the empty message when a genre has no movies', (
    tester,
  ) async {
    await pumpMovieList(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '드라마'));
    await tester.pumpAndSettle();

    expect(find.text('표시할 영화가 없습니다.'), findsOneWidget);
    expect(find.byType(MoviePosterCard), findsNothing);
  });

  testWidgets('shows the error and reloads on retry', (tester) async {
    adapter.responder = (_) => (500, const {});
    await pumpMovieList(tester);
    await tester.pumpAndSettle();

    expect(find.text('영화를 불러오지 못했어요. 다시 시도해 주세요.'), findsOneWidget);

    adapter.responder = _respond;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.byType(MoviePosterCard), findsNWidgets(3));
  });

  testWidgets('tapping a movie passes the TMDB id to the detail screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/movies',
      routes: [
        GoRoute(
          path: '/movies',
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) =>
                MovieListViewModel(fakeTmdbService(adapter))..loadInitial(),
            child: const MovieListScreen(),
          ),
        ),
        GoRoute(
          path: '/movies/:movieId',
          builder: (context, state) => MovieDetailScreen(
            movieId: int.tryParse(state.pathParameters['movieId'] ?? ''),
            movie: state.extra as Movie?,
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('영화 2'));
    await tester.pumpAndSettle();

    final detail = tester.widget<MovieDetailScreen>(
      find.byType(MovieDetailScreen),
    );
    expect(detail.movieId, 2);
    expect(find.text('영화 2'), findsOneWidget);

    // 평점 Dialog까지 열리는지 확인
    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
