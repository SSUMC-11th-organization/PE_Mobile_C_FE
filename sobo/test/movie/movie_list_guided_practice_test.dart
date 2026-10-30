import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:movielog/screens/movie/movie_list_screen.dart';
import 'package:movielog/widgets/movie/cards/movie_grid.dart';

void main() {
  setUp(() {
    // 실제 기기 저장소 대신 매 테스트마다 비어 있는 메모리 저장소 사용
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  testWidgets('800ms까지 로딩을 표시하고 1초 뒤 영화 Grid를 표시한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: MovieListScreen(selectedGenres: [])),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(MovieGrid), findsNothing);

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.widget<MovieGrid>(find.byType(MovieGrid)).movies.length, 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('장르 변경으로 다시 build해도 조회를 다시 시작하지 않는다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MovieListScreen(selectedGenres: [])),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    await tester.pumpWidget(
      const MaterialApp(home: MovieListScreen(selectedGenres: ['SF'])),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final filteredMovies = tester
        .widget<MovieGrid>(find.byType(MovieGrid))
        .movies;
    expect(filteredMovies.length, 1);
    expect(filteredMovies.single.genre, 'SF');
    expect(tester.takeException(), isNull);
  });

  testWidgets('성공 화면의 영화 카드를 누르면 기존 상세 경로로 이동한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/movies',
      routes: [
        GoRoute(
          path: '/movies',
          builder: (context, state) =>
              const MovieListScreen(selectedGenres: []),
          routes: [
            GoRoute(
              path: ':movieId',
              builder: (context, state) => Scaffold(
                body: Text('상세 영화 ${state.pathParameters['movieId']}'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('별빛 아래 우리'));
    await tester.pumpAndSettle();
    expect(find.text('상세 영화 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('영화가 한 편이어도 당겨서 새로고침하고 선택 장르를 유지한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: MovieListScreen(selectedGenres: ['SF'])),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(tester.widget<MovieGrid>(find.byType(MovieGrid)).movies.length, 1);

    await tester.drag(find.byType(GridView), const Offset(0, 350));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.byType(MovieGrid), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final refreshedMovies = tester
        .widget<MovieGrid>(find.byType(MovieGrid))
        .movies;
    expect(refreshedMovies.length, 1);
    expect(refreshedMovies.single.genre, 'SF');
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
