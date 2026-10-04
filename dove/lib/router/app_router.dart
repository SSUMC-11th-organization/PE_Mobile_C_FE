import 'package:go_router/go_router.dart';
import 'package:movielog/screen/home_screen.dart';
import 'package:movielog/screen/main_screen.dart';
import 'package:movielog/screen/movie_detail_screen.dart';
import 'package:movielog/screen/movie_list_screen.dart';
import 'package:movielog/screen/profile_screen.dart';
import 'package:movielog/screen/signup_screen.dart';
import 'package:movielog/screen/start_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScreen(navigationShell: navigationShell),
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
                builder: (context, state) => MovieListScreen(
                  selectedGenres: (state.uri.queryParametersAll['genre'] ?? [])
                      .toSet(),
                ),
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
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) =>
            MovieDetailScreen(movieId: state.pathParameters['movieId']!),
      ),
    ],
  );
}
