// 내가 등록한 평점 화면 테스트
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:movielog/screens/main_screen.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/screens/profile_screen.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';

import 'helpers/fake_movielog.dart';

// 실제 AppRouter와 같은 구조: 탭(ShellRoute) 안의 /my 아래에 ratings를 두고 root Navigator에 표시
Widget _app(FakeMovieLogAdapter ratingServer, FakeMovieLogAdapter tmdbServer) {
  final rootKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    initialLocation: '/my',
    navigatorKey: rootKey,
    routes: [
      ShellRoute(
        builder: (_, _, child) => MainScreen(currentIndex: 2, child: child),
        routes: [
          GoRoute(
            path: '/my',
            builder: (_, _) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'ratings',
                parentNavigatorKey: rootKey,
                builder: (_, _) => ChangeNotifierProvider(
                  create: (_) => MyRatingsViewModel(
                    RatingApiService(fakeDio(ratingServer)),
                    TmdbMovieService(fakeDio(tmdbServer)),
                    1, // 학습용 회원 ID
                  )..load(),
                  child: const MyRatingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  return MaterialApp.router(theme: AppTheme.light, routerConfig: router);
}

FakeMovieLogAdapter _tmdb() => FakeMovieLogAdapter(
  (options) => (200, movieDetailJson(int.parse(options.path.split('/').last))),
);

Future<void> _openRatings(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.text('내가 등록한 평점'), 200);
  await tester.tap(find.text('내가 등록한 평점'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('My page → ratings screen with back button and titles', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(FakeMovieLogAdapter((_) => (200, sampleRatingsJson())), _tmdb()),
    );
    await _openRatings(tester);

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.centerTitle, isTrue);
    expect(find.byType(BackButton), findsOneWidget);
    // 탭 화면(MainScreen)의 NavigationBar가 보이지 않아야 함
    expect(find.byType(NavigationBar).hitTestable(), findsNothing);

    expect(find.text('영화 13'), findsOneWidget);
    expect(find.text('영화 550'), findsOneWidget);
    expect(find.text('최고의 영화!'), findsOneWidget);
    expect(find.text('별점 3 / 5'), findsOneWidget);
    expect(find.text('별점 5 / 5'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(MyRatingsScreen), findsNothing);
    expect(find.byType(NavigationBar).hitTestable(), findsOneWidget);
  });

  testWidgets('a movie TMDB could not find shows its id', (tester) async {
    final tmdb = FakeMovieLogAdapter(
      (options) => options.path.endsWith('/13')
          ? (404, {'status_message': 'not found'})
          : (200, movieDetailJson(550)),
    );
    await tester.pumpWidget(
      _app(FakeMovieLogAdapter((_) => (200, sampleRatingsJson())), tmdb),
    );
    await _openRatings(tester);

    expect(find.text('영화 #13'), findsOneWidget);
    expect(find.text('포스터 정보 없음'), findsOneWidget);
  });

  testWidgets('shows the empty message', (tester) async {
    await tester.pumpWidget(
      _app(FakeMovieLogAdapter((_) => (200, <Object>[])), _tmdb()),
    );
    await _openRatings(tester);

    expect(find.textContaining('아직 등록한 평점이 없어요'), findsOneWidget);
  });

  testWidgets('shows the error message and retries', (tester) async {
    final server = FakeMovieLogAdapter((_) => (404, {'statusCode': 404}));
    await tester.pumpWidget(_app(server, _tmdb()));
    await _openRatings(tester);

    expect(find.text('존재하지 않는 회원입니다.'), findsOneWidget);

    server.route = (_) => (200, sampleRatingsJson());
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('영화 550'), findsOneWidget);
  });

  group('수정·삭제 버튼', () {
    testWidgets('edit opens RatingDialog with the saved score and comment', (
      tester,
    ) async {
      final server = FakeMovieLogAdapter(
        (options) => options.method == 'PATCH'
            ? (
                409,
                {
                  'isSuccess': false,
                  'code': 'RATING409',
                  'message': '같은 내용으로는 수정할 수 없습니다.',
                },
              )
            : (200, sampleRatingsJson()),
      );
      await tester.pumpWidget(_app(server, _tmdb()));
      await _openRatings(tester);

      // 두 번째 카드: 5점 · '최고의 영화!'
      await tester.tap(find.byTooltip('수정').at(1));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '최고의 영화!');

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      final patch = server.requests.firstWhere((r) => r.method == 'PATCH');
      expect(patch.path, '/v6/members/1/ratings/1');
      expect(patch.data, {'score': 5, 'comment': '최고의 영화!'});
      // 409는 서버 문구로 Dialog 안에 안내하고 입력은 그대로 둠
      expect(find.text('같은 내용으로는 수정할 수 없습니다.'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('a null comment starts as an empty field', (tester) async {
      await tester.pumpWidget(
        _app(FakeMovieLogAdapter((_) => (200, sampleRatingsJson())), _tmdb()),
      );
      await _openRatings(tester);

      await tester.tap(find.byTooltip('수정').first);
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty);
    });

    testWidgets('canceling delete sends no request', (tester) async {
      final server = FakeMovieLogAdapter((_) => (200, sampleRatingsJson()));
      await tester.pumpWidget(_app(server, _tmdb()));
      await _openRatings(tester);

      await tester.tap(find.byTooltip('삭제').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(server.requests.where((r) => r.method == 'DELETE'), isEmpty);
    });

    testWidgets('deleting the last rating shows the empty UI', (tester) async {
      var ratings = [sampleRatingsJson().first];
      final server = FakeMovieLogAdapter((options) {
        if (options.method == 'DELETE') {
          ratings = [];
          return (204, {});
        }
        return (200, ratings);
      });
      await tester.pumpWidget(_app(server, _tmdb()));
      await _openRatings(tester);

      await tester.tap(find.byTooltip('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(
        server.requests.singleWhere((r) => r.method == 'DELETE').path,
        '/v6/members/1/ratings/3',
      );
      expect(find.textContaining('아직 등록한 평점이 없어요'), findsOneWidget);
      expect(find.text('평점을 삭제했어요'), findsOneWidget);
    });
  });
}
