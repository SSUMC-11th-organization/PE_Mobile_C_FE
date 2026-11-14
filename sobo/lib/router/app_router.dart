import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../screens/movie_detail_loader.dart';
import '../services/sign_up_service.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/sign_up_view_model.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/start_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie/movie_list_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../services/tmdb_movie_service.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../screens/my_ratings_screen.dart';
import '../services/rating_api_service.dart';
import '../view_models/my_ratings_view_model.dart';

class AppRouter {
  AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    initialLocation: '/start',
    navigatorKey: rootNavigatorKey,
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          return ChangeNotifierProvider<SignUpViewModel>(
            create: (context) => SignUpViewModel(context.read<SignUpService>()),
            child: const SignUpScreen(),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
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
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movies',
                builder: (context, state) => ChangeNotifierProvider<MovieListViewModel>(
                  create: (context) => MovieListViewModel(context.read<TmdbMovieService>())..loadInitial(),
                  child: const MovieListScreen(),
                ),
                routes: [
                  GoRoute(
                    path: ':movieId',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['movieId'] ?? '');
                      if (id == null || id < 1) {
                        return const Scaffold(body: Center(child: Text('영화 ID가 올바르지 않습니다.')));
                      }
                      final extra = state.extra;
                      return MovieDetailLoader(
                        movieId: id,
                        initialMovie: extra is TmdbMovieDto && extra.id == id ? extra : null,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'ratings', // /my Route 아래의 자식, root Navigator에 표시
                    parentNavigatorKey: AppRouter.rootNavigatorKey,
                    builder: (context, state) {
                      final id = context.read<LearningMemberSession>().memberId;
                      if (id == null) {
                        return Scaffold(
                          appBar: AppBar(centerTitle: true, title: const Text('내가 등록한 평점')),
                          body: const Center(child: Text('학습용 회원가입이 필요합니다.')),
                        );
                      }
                      return ChangeNotifierProvider<MyRatingsViewModel>(
                        create: (context) => MyRatingsViewModel(
                          context.read<RatingApiService>(),
                          context.read<TmdbMovieService>(),
                          id,
                        )..load(),
                        child: const MyRatingsScreen(),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
