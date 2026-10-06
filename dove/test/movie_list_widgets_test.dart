import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/mock_movies.dart';
import 'package:movielog/widgets/movie_widget/movie_card.dart';
import 'package:movielog/widgets/movie_widget/movie_grid.dart';
import 'package:movielog/widgets/movie_widget/movie_list_empty.dart';
import 'package:movielog/widgets/movie_widget/movie_list_error.dart';
import 'package:movielog/widgets/movie_widget/movie_list_loading.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('Loading은 Skeleton 카드를 보여준다', (tester) async {
    await tester.pumpWidget(wrap(const MovieListLoading()));

    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(FadeTransition), findsWidgets);
    expect(find.byType(MovieCard), findsNothing);
  });

  testWidgets('Empty는 안내 문구를 보여준다', (tester) async {
    await tester.pumpWidget(wrap(const MovieListEmpty()));

    expect(find.text('조건에 맞는 영화가 없습니다.'), findsOneWidget);
  });

  testWidgets('Error는 안내와 다시 시도 버튼을 보여주고 탭을 전달한다', (tester) async {
    var retried = 0;
    await tester.pumpWidget(wrap(MovieListError(onRetry: () => retried++)));

    expect(find.text('영화를 불러오지 못했어요.'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);

    await tester.tap(find.text('다시 시도'));
    expect(retried, 1);
  });

  testWidgets('Success는 영화 카드를 보여준다', (tester) async {
    await tester.pumpWidget(
      wrap(MovieGrid(movies: mockMovies.take(2).toList())),
    );

    expect(find.byType(MovieCard), findsNWidgets(2));
    expect(find.text('별빛 아래 우리'), findsWidgets);
  });
}
