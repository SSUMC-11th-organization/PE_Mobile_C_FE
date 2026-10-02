import 'package:go_router/go_router.dart';
import 'package:movielog/screen/home_screen.dart';
import 'package:movielog/screen/main_screen.dart';
import 'package:movielog/screen/movie_detail_screen.dart';
import 'package:movielog/screen/movie_list_screen.dart';
import 'package:movielog/screen/profile_screen.dart';
import 'package:movielog/screen/sign_up_screen.dart';
import 'package:movielog/screen/start_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const SignUpScreen(),
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
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movies',
                builder: (context, state) {
                  final genreParam = state.uri.queryParameters['genre'];
                  final initialGenres =
                      (genreParam == null || genreParam.isEmpty)
                      ? const <String>[]
                      : genreParam.split(',');
                  return MovieListScreen(initialGenres: initialGenres);
                },
                routes: [
                  GoRoute(
                    path: ':movieId',
                    builder: (context, state) {
                      final movieId = int.parse(
                        state.pathParameters['movieId']!,
                      );
                      return MovieDetailScreen(movieId: movieId);
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
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
