// 홈 화면 인기 영화 테스트
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/screens/home_screen.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/widgets/movie_poster_image.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_tmdb.dart';

Future<MovieHomeViewModel> _pumpHome(
  WidgetTester tester,
  FakeTmdbAdapter adapter,
) async {
  tester.view.physicalSize = const Size(390, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final viewModel = MovieHomeViewModel(fakeTmdbService(adapter))..loadPopular();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: viewModel,
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return viewModel;
}

void main() {
  testWidgets('shows only the top 5 popular movies', (tester) async {
    final viewModel = await _pumpHome(
      tester,
      FakeTmdbAdapter(body: moviePageJson(8)),
    );

    expect(viewModel.status, MovieHomeLoadStatus.success);
    expect(viewModel.popularMovies.map((movie) => movie.id), [
      101,
      102,
      103,
      104,
      105,
    ]);
    expect(find.text('인기 영화 1'), findsOneWidget);
    expect(find.text('인기 영화 6'), findsNothing);
  });

  testWidgets('shows fewer than 5 movies without a range error', (
    tester,
  ) async {
    await _pumpHome(tester, FakeTmdbAdapter(body: moviePageJson(1)));

    expect(find.text('인기 영화 1'), findsOneWidget);
    expect(find.text('지금 인기 있는 영화'), findsNothing);
  });

  testWidgets('does not request again when the home screen rebuilds', (
    tester,
  ) async {
    final adapter = FakeTmdbAdapter(body: moviePageJson(5));
    final viewModel = await _pumpHome(tester, adapter);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const MaterialApp(home: HomeScreen(key: ValueKey('rebuilt'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(adapter.requests, hasLength(1));
  });

  testWidgets('shows a placeholder when the poster is null', (tester) async {
    await _pumpHome(
      tester,
      FakeTmdbAdapter(body: moviePageJson(1, withPoster: false)),
    );

    expect(find.byType(PosterPlaceholder), findsOneWidget);
  });

  testWidgets('shows the error and reloads on retry', (tester) async {
    final adapter = FakeTmdbAdapter(statusCode: 401);
    await _pumpHome(tester, adapter);

    expect(find.text('인기 영화를 불러오지 못했어요.'), findsOneWidget);

    adapter
      ..statusCode = 200
      ..body = moviePageJson(5);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(adapter.requests, hasLength(2));
    expect(find.text('인기 영화 1'), findsOneWidget);
  });
}
