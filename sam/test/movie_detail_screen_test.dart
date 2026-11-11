// 영화 상세 화면 테스트 (MovieDetailLoader → MovieDetailScreen + 평점 등록)
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:movielog/data/mock_movies.dart';
import 'package:movielog/data/models/movie.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/movie_detail_loader.dart';
import 'package:movielog/screens/movie_detail_screen.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/widgets/movie_card.dart';
import 'package:movielog/widgets/rating_dialog.dart';

import 'helpers/fake_movielog.dart';
import 'helpers/fake_tmdb.dart';

// 실제 AppRouter의 /movies/:movieId와 같은 방식으로 Loader를 띄움
Widget _app({
  int? memberId,
  FakeMovieLogAdapter? ratingServer,
  FakeTmdbAdapter? tmdbServer,
}) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) =>
            Scaffold(body: MovieCard(movie: movies.first)),
      ),
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['movieId']!);
          final extra = state.extra;
          return MovieDetailLoader(
            movieId: id,
            initialMovie: extra is Movie && extra.id == id ? extra : null,
          );
        },
      ),
    ],
  );
  final session = LearningMemberSession();
  if (memberId != null) session.setMemberId(memberId);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: session),
      Provider(
        create: (_) => RatingApiService(
          fakeDio(ratingServer ?? FakeMovieLogAdapter((_) => (201, {}))),
        ),
      ),
      Provider(
        create: (_) =>
            fakeTmdbService(tmdbServer ?? FakeTmdbAdapter(statusCode: 404)),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// 휴대폰 크기로 맞춰 포스터 아래 영화 정보까지 그려지게 함
void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _openDetail(WidgetTester tester) async {
  _usePhoneSize(tester);
  await tester.tap(find.byType(MovieCard));
  await tester.pumpAndSettle();
}

// 별점 n개째 별을 누름
Future<void> _tapStar(WidgetTester tester, int index) async {
  final star = find.descendant(
    of: find.byType(RatingDialog),
    matching: find.byIcon(Icons.star),
  );
  await tester.tap(star.at(index - 1));
  await tester.pump();
}

void main() {
  testWidgets('tapping a movie card opens its detail screen', (tester) async {
    await tester.pumpWidget(_app());
    await _openDetail(tester);

    expect(find.byType(MovieDetailScreen), findsOneWidget);
    expect(find.text('Cinema Archive'), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsOneWidget);
    expect(find.text('2024 • 드라마'), findsOneWidget);
  });

  testWidgets('loads the movie from TMDB when nothing was passed', (
    tester,
  ) async {
    _usePhoneSize(tester);
    final tmdb = FakeTmdbAdapter(responder: (_) => (200, movieDetailJson(550)));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LearningMemberSession()),
          Provider(
            create: (_) => RatingApiService(
              fakeDio(FakeMovieLogAdapter((_) => (201, {}))),
            ),
          ),
          Provider<TmdbMovieService>(create: (_) => fakeTmdbService(tmdb)),
        ],
        child: const MaterialApp(home: MovieDetailLoader(movieId: 550)),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('영화 550'), findsOneWidget);
  });

  testWidgets('shows a message when the movie cannot be loaded', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LearningMemberSession()),
          Provider(
            create: (_) => RatingApiService(
              fakeDio(FakeMovieLogAdapter((_) => (201, {}))),
            ),
          ),
          Provider<TmdbMovieService>(
            create: (_) => fakeTmdbService(FakeTmdbAdapter(statusCode: 404)),
          ),
        ],
        child: const MaterialApp(home: MovieDetailLoader(movieId: 999)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('영화를 불러오지 못했습니다.'), findsOneWidget);
  });

  testWidgets('shows the average rating as a read-only indicator', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await _openDetail(tester);

    await tester.scrollUntilVisible(
      find.byType(RatingBarIndicator),
      200,
      scrollable: find
          .descendant(
            of: find.byType(MovieDetailScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final indicator = tester.widget<RatingBarIndicator>(
      find.byType(RatingBarIndicator),
    );
    expect(indicator.rating, 4.5);
    expect(find.text('4.5'), findsOneWidget);
  });

  testWidgets('toggles favorite with a snackbar and icon change', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await _openDetail(tester);

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

  testWidgets('asks to sign up first when there is no member', (tester) async {
    await tester.pumpWidget(_app());
    await _openDetail(tester);

    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();

    expect(find.byType(RatingDialog), findsNothing);
    expect(find.text('먼저 회원가입을 완료해 주세요.'), findsOneWidget);
  });

  testWidgets('creates a rating for the session member', (tester) async {
    final server = FakeMovieLogAdapter((_) => (201, {}));
    await tester.pumpWidget(_app(memberId: 7, ratingServer: server));
    await _openDetail(tester);

    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    expect(find.byType(RatingDialog), findsOneWidget);

    await _tapStar(tester, 4);
    await tester.enterText(find.byType(TextField), '  다시 보고 싶어요  ');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.byType(RatingDialog), findsNothing);
    expect(find.text('4점을 남겼어요'), findsOneWidget);

    final request = server.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/v6/members/7/ratings');
    expect(request.data, {
      'movieId': movies.first.id,
      'score': 4,
      'comment': '다시 보고 싶어요',
    });
  });

  testWidgets('keeps the dialog open with an error when saving fails', (
    tester,
  ) async {
    final server = FakeMovieLogAdapter(
      (_) => (
        409,
        {'isSuccess': false, 'code': 'RATING409', 'message': '이미 등록한 영화입니다.'},
      ),
    );
    await tester.pumpWidget(_app(memberId: 7, ratingServer: server));
    await _openDetail(tester);

    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    await _tapStar(tester, 3);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.byType(RatingDialog), findsOneWidget);
    expect(find.text('저장하지 못했습니다. 잠시 후 다시 시도해 주세요.'), findsOneWidget);
    // 실패는 성공과 다른 문구(서버 message)로 SnackBar 안내
    expect(find.text('이미 등록한 영화입니다.'), findsOneWidget);
    expect(find.textContaining('점을 남겼어요'), findsNothing);
  });
}
