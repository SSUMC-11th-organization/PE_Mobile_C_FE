import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/home_screen.dart';
import 'package:movielog/screens/main_screen.dart';
import 'package:movielog/screens/movie_detail_screen.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/screens/my_page_screen.dart';
import 'package:movielog/screens/my_rating_screen.dart';
import 'package:movielog/screens/register_screen.dart';
import 'package:movielog/screens/start_screen.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:provider/provider.dart';

class AppRouter {
  AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    initialLocation: '/start',
    navigatorKey: rootNavigatorKey,
    routes: [
      // 하단 네비게이션이 없는 화면
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // 하단 네비게이션이 있는 탭 화면
      ShellRoute(
        builder: (context, state, child) {
          return MainScreen(
            currentIndex: indexFromLocation(state.uri.path),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                ChangeNotifierProvider<MovieHomeViewModel>(
                  create: (context) =>
                      MovieHomeViewModel(context.read<TmdbMovieService>())
                        ..loadPopular(),
                  child: const HomeScreen(),
                ),
          ),
          GoRoute(
            path: '/movies',
            builder: (context, state) {
              final genreParam = state.uri.queryParameters['genre'];
              final initialGenres = (genreParam == null || genreParam.isEmpty)
                  ? const <String>[]
                  : genreParam.split(',');
              return ChangeNotifierProvider<MovieListViewModel>(
                create: (context) =>
                    MovieListViewModel(context.read<TmdbMovieService>())
                      ..loadInitial(),
                child: MovieListScreen(initialGenres: initialGenres),
              );
            },
            routes: [
              GoRoute(
                path: ':movieId',
                builder: (context, state) {
                  final movieId = int.parse(state.pathParameters['movieId']!);
                  return ChangeNotifierProvider<MovieDetailViewModel>(
                    create: (context) => MovieDetailViewModel(
                      context.read<TmdbMovieService>(),
                      movieId,
                    )..load(),
                    child: MovieDetailScreen(movieId: movieId),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/my',
            builder: (context, state) => const MyPageScreen(),
            routes: [
              GoRoute(
                path: 'ratings', // 최종 경로: /my/ratings
                parentNavigatorKey: rootNavigatorKey, // 하단 NavigationBar를 가립니다.
                builder: (context, state) =>
                    ChangeNotifierProvider<MyRatingsViewModel>(
                      create: (context) => MyRatingsViewModel(
                        context.read<RatingApiService>(),
                        context.read<TmdbMovieService>(),
                        sampleMemberId, // 6주차는 학습용 ID 1입니다.
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

  static int indexFromLocation(String path) {
    if (path.startsWith('/movies')) return 1;
    if (path.startsWith('/my')) return 2;
    return 0;
  }
}
