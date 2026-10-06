import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screen/home_screen.dart';
import 'package:movielog/screen/movie_detail_screen.dart';
import 'package:movielog/screen/start_screen.dart';
import 'package:movielog/screen/movie_list_screen.dart';
import 'package:movielog/services/genre_preference.dart';
import 'package:movielog/services/movie_service.dart';
import 'package:movielog/services/sort_preference.dart';
import 'package:movielog/models/movie_sort.dart';
import 'package:movielog/widgets/movie_widget/movie_card.dart';
import 'package:movielog/widgets/movie_widget/movie_grid.dart';
import 'package:movielog/widgets/movie_widget/movie_list_loading.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('앱 실행 시 시작 화면이 표시된다', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(StartScreen), findsOneWidget);
  });

  testWidgets('영화 목록은 Loading 후 Success 상태로 바뀐다', (tester) async {
    await tester.pumpWidget(const MyApp());
    AppRouter.router.go('/movies');
    await tester.pump();

    expect(find.byType(MovieListLoading), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.byType(MovieListLoading), findsNothing);
    expect(find.text('별빛 아래 우리'), findsWidgets);
  });

  testWidgets('빈 목록 모드에서는 Empty 안내가 표시된다', (tester) async {
    await tester.pumpWidget(const MyApp());
    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.science_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('빈 목록'));
    await tester.pumpAndSettle();

    expect(find.text('조건에 맞는 영화가 없습니다.'), findsOneWidget);
  });

  testWidgets('실패 모드에서는 Error가 표시되고 다시 시도하면 Success가 된다', (tester) async {
    await tester.pumpWidget(const MyApp());
    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.science_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('실패'));
    await tester.pump();
    expect(find.byType(MovieListLoading), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('영화를 불러오지 못했어요.'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);

    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    expect(find.byType(MovieListLoading), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('영화를 불러오지 못했어요.'), findsNothing);
    expect(find.text('별빛 아래 우리'), findsWidgets);
  });

  testWidgets('장르 Chip을 누르면 목록이 갱신되고 선택 장르가 저장된다', (tester) async {
    await tester.pumpWidget(const MyApp());
    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'SF'));
    await tester.pumpAndSettle();

    expect(find.text('별빛 아래 우리'), findsNothing);
    expect(find.text('우주의 끝에서'), findsWidgets);
    expect(await GenrePreference().read(), 'SF');
  });

  testWidgets('저장된 장르가 있으면 목록 진입 시 복원된다', (tester) async {
    await GenrePreference().save('SF');

    await tester.pumpWidget(const MyApp());
    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'SF'),
    );
    expect(chip.selected, isTrue);
    expect(find.text('별빛 아래 우리'), findsNothing);
    expect(find.text('우주의 끝에서'), findsWidgets);
  });

  testWidgets('목록에서 상세로 이동하고 뒤로 돌아온다', (tester) async {
    await tester.pumpWidget(const MyApp());
    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();

    await tester.tap(find.text('별빛 아래 우리').first);
    await tester.pumpAndSettle();
    expect(find.byType(MovieDetailScreen), findsOneWidget);

    AppRouter.router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(MovieDetailScreen), findsNothing);
  });

  testWidgets('상세에서 즐겨찾기 Snackbar와 평점 Dialog가 동작한다', (tester) async {
    await tester.pumpWidget(const MyApp());
    AppRouter.router.go('/home');
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    AppRouter.router.push('/movies/1');
    await tester.pumpAndSettle();

    await tester.tap(find.text('즐겨찾기'));
    await tester.pump();
    expect(find.text('즐겨찾기에 추가했어요.'), findsOneWidget);

    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    expect(find.text('영화는 어떠셨나요?'), findsOneWidget);
  });

  testWidgets('탭을 오가도 영화 탭의 선택 장르가 유지된다', (tester) async {
    await tester.pumpWidget(const MyApp());
    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'SF'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.movie_outlined));
    await tester.pumpAndSettle();
    expect(find.text('별빛 아래 우리'), findsNothing);
    expect(find.text('우주의 끝에서'), findsWidgets);
  });

  testWidgets('응답이 지연되면 Timeout 안내가 표시된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MovieListScreen(
          movieService: FakeMovieService(
            delay: Duration(milliseconds: 10),
            timeoutDelay: Duration(milliseconds: 500),
          ),
          timeout: Duration(milliseconds: 100),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('별빛 아래 우리'), findsWidgets);

    await tester.tap(find.byIcon(Icons.science_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('응답 지연'));
    await tester.pump();
    expect(find.byType(MovieListLoading), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();

    expect(find.text('응답이 너무 오래 걸리고 있어요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('당겨서 새로고침하면 Skeleton 없이 목록이 갱신된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MovieListScreen(
          movieService: FakeMovieService(delay: Duration(milliseconds: 300)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MovieGrid), findsOneWidget);

    await tester.fling(find.byType(MovieGrid), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(RefreshProgressIndicator), findsOneWidget);
    expect(find.byType(MovieListLoading), findsNothing);
    expect(find.byType(MovieGrid), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(find.byType(MovieGrid), findsOneWidget);
  });

  testWidgets('정렬을 선택하면 목록 순서가 바뀌고 저장된다', (tester) async {
    await tester.pumpWidget(const MyApp());
    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();

    String firstTitle() =>
        tester.widget<MovieCard>(find.byType(MovieCard).first).movie.title;

    expect(firstTitle(), '별빛 아래 우리');

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    await tester.tap(find.text('평점순'));
    await tester.pumpAndSettle();

    expect(firstTitle(), '기억의 숲');
    expect(await SortPreference().read(), MovieSort.rating);
  });

  testWidgets('저장된 정렬이 목록 진입 시 복원된다', (tester) async {
    await SortPreference().save(MovieSort.title);

    await tester.pumpWidget(const MyApp());
    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();

    final first = tester
        .widget<MovieCard>(find.byType(MovieCard).first)
        .movie
        .title;
    expect(first, '기억의 숲');
  });
}
