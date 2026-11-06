import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../services/member_check_service.dart';
import '../view_models/sign_up_view_model.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/start_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie/movie_detail_screen.dart';
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
            create: (_) => SignUpViewModel(
              MemberCheckService(
                Dio(
                  BaseOptions(
                    baseUrl: 'https://workbook.devnoco.com',
                    connectTimeout: const Duration(seconds: 10),
                    receiveTimeout: const Duration(seconds: 10),
                  ),
                ),
              ),
            ),
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
                builder: (context, state) =>
                    ChangeNotifierProvider<MovieListViewModel>(
                      create: (context) =>
                          MovieListViewModel(context.read<TmdbMovieService>())
                            ..loadInitial(),
                      child: const MovieListScreen(),
                    ),
                routes: [
                  GoRoute(
                    path: ':movieId',
                    builder: (context, state) {
                      final extra = state.extra;
                      final movieId = int.tryParse(
                        state.pathParameters['movieId'] ?? '',
                      );

                      if (extra is! TmdbMovieDto || extra.id != movieId) {
                        return Scaffold(
                          appBar: AppBar(title: const Text('영화 상세')),
                          body: const Center(
                            child: Text('영화 목록에서 영화를 다시 선택해주세요.'),
                          ),
                        );
                      }

                      return MovieDetailScreen(movie: extra);
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
                    path: 'ratings',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      return ChangeNotifierProvider<MyRatingsViewModel>(
                        create: (context) => MyRatingsViewModel(
                          context.read<RatingApiService>(),
                          context.read<TmdbMovieService>(),
                          sampleMemberId,
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
