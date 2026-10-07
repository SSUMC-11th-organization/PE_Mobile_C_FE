import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/mock_movie.dart';
import 'package:movielog/widgets/movie/movie_grid.dart';
import 'package:movielog/widgets/movie/movie_list_empty.dart';
import 'package:movielog/widgets/movie/movie_list_error.dart';
import 'package:movielog/widgets/movie/movie_list_loading.dart';

void main() {
  testWidgets('Loading: 스켈레톤 카드가 그려진다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MovieListLoading())),
    );

    expect(find.byType(MovieListLoading), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing); // 스피너 대신 스켈레톤
  });

  testWidgets('Empty: 안내 문구가 보인다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MovieListEmpty())),
    );

    expect(find.text('조건에 맞는 영화가 없습니다.'), findsOneWidget);
  });

  testWidgets('Error: 문구와 "다시 시도" 버튼이 보인다. 버튼을 누르면 onRetry가 호출된다', (
    tester,
  ) async {
    var retryCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MovieListError(
            message: '영화를 불러오지 못했습니다.',
            onRetry: () => retryCount++,
          ),
        ),
      ),
    );
    expect(find.text('영화를 불러오지 못했습니다.'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pump();

    expect(retryCount, 1);
  });

  testWidgets('Success: 영화 제목이 보인다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MovieGrid(movies: movies)),
      ),
    );

    expect(find.text(movies.first.title), findsOneWidget);
  });
}
