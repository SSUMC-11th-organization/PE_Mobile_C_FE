import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../screens/movie_detail_loader.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/favorite_api_service.dart';
import '../view_models/sign_up_view_model.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/movie_search_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/my_page_screen.dart';
import '../data/services/tmdb_movie_service.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/member_api_service.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../data/services/rating_api_service.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../view_models/session_ratings_store.dart';
import '../view_models/favorite_detail_view_model.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/paged_movies_view_model.dart';
import '../core/session/session_guard.dart';
import '../widgets/movielog_button.dart';

String? authRedirect(AuthStatus status, String location) {
  const publicPaths = {'/login', '/register'};
  final atStart = location == '/start';
  final atPublic = publicPaths.contains(location);

  return switch (status) {
    // 토큰 확인 중 또는 확인 실패(재시도 버튼): 스플래시 화면 유지
    AuthStatus.initializing ||
    AuthStatus.retryRequired => atStart ? null : '/start',

    // 로그아웃 또는 로그인 요청 중: 공개 화면만 허용
    AuthStatus.signedOut ||
    AuthStatus.authenticating => atPublic ? null : '/login',

    // 로그인됨: 스플래시와 로그인·회원가입 화면은 홈으로 보냄
    AuthStatus.signedIn => (atStart || atPublic) ? '/home' : null,
  };
}

class AppRouter {
  AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthViewModel authViewModel) {
    return GoRouter(
      initialLocation: '/start',
      navigatorKey: rootNavigatorKey,
      refreshListenable: authViewModel,
      redirect: (context, state) {
        return authRedirect(authViewModel.status, state.uri.path);
      },
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) {
            final auth = context.watch<AuthViewModel>();
            return SplashScreen(
              message: auth.message,
              onRetry: auth.status == AuthStatus.retryRequired
                  ? auth.restoreSession
                  : null,
            );
          },
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) {
            return ChangeNotifierProvider<SignUpViewModel>(
              create: (context) =>
                  SignUpViewModel(context.read<SignUpService>()),
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
                  builder: (context, state) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider<MovieListViewModel>(
                        create: (context) => MovieListViewModel(
                          context.read<TmdbMovieService>(),
                        ),
                      ),
                      ChangeNotifierProvider<PagedMoviesViewModel>(
                        create: (context) => PagedMoviesViewModel(
                          tmdbApi: context.read<TmdbMovieService>(),
                        )..loadInitial(),
                      ),
                    ],
                    child: const MovieListScreen(),
                  ),
                  routes: [
                    GoRoute(
                      path: 'search',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          ChangeNotifierProvider<PagedMoviesViewModel>(
                            create: (context) => PagedMoviesViewModel(
                              tmdbApi: context.read<TmdbMovieService>(),
                            ),
                            child: MovieSearchScreen(
                              onOpenMovie: (movie) async {
                                await context.push(
                                  '/movies/${movie.id}',
                                  extra: movie,
                                );
                              },
                            ),
                          ),
                    ),
                    GoRoute(
                      path: ':movieId',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final id = int.tryParse(
                          state.pathParameters['movieId'] ?? '',
                        );
                        if (id == null || id < 1) {
                          return Scaffold(
                            body: Center(child: Text('영화 ID가 올바르지 않습니다.')),
                          );
                        }
                        final auth = context.watch<AuthViewModel>();
                        final member = auth.member;
                        final guard = context.read<SessionGuard>();
                        if (member == null) {
                          return Scaffold(
                            appBar: AppBar(title: const Text('영화 상세')),
                            body: Center(
                              child: auth.memberStatus == MemberLoadStatus.error
                                  ? Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: MovieLogButton(
                                        label: '내 정보 다시 불러오기',
                                        onPressed: () =>
                                            auth.loadMember(force: true),
                                      ),
                                    )
                                  : const CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (guard.accountId != member.email) {
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final extra = state.extra;
                        return ChangeNotifierProvider<FavoriteDetailViewModel>(
                          key: ValueKey((member.email, guard.generation, id)),
                          create: (context) => FavoriteDetailViewModel(
                            movieId: id,
                            favoriteApi: context.read<FavoriteApiService>(),
                            sessionGuard: guard,
                            accountId: member.email,
                            auth: auth,
                          ),
                          child: MovieDetailLoader(
                            movieId: id,
                            initialMovie:
                                extra is TmdbMovieDto && extra.id == id
                                ? extra
                                : null,
                          ),
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
                  builder: (context, state) => const MyPageScreen(),
                  routes: [
                    GoRoute(
                      path: 'profile/edit',
                      parentNavigatorKey: AppRouter.rootNavigatorKey,
                      builder: (context, state) {
                        final auth = context.watch<AuthViewModel>();

                        if (auth.member == null) {
                          return Scaffold(
                            appBar: AppBar(
                              centerTitle: true,
                              title: const Text('프로필 수정'),
                            ),
                            body: Center(
                              child: auth.memberStatus == MemberLoadStatus.error
                                  ? Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: MovieLogButton(
                                        label: '다시 시도',
                                        onPressed: () =>
                                            auth.loadMember(force: true),
                                      ),
                                    )
                                  : const CircularProgressIndicator(),
                            ),
                          );
                        }

                        return ChangeNotifierProvider<EditProfileViewModel>(
                          create: (context) => EditProfileViewModel(
                            context.read<MemberApiService>(),
                            auth,
                          ),
                          child: const EditProfileScreen(),
                        );
                      },
                    ),
                    GoRoute(
                      path: 'favorites',
                      parentNavigatorKey: AppRouter.rootNavigatorKey,
                      builder: (context, state) {
                        final auth = context.watch<AuthViewModel>();
                        final member = auth.member;
                        final guard = context.read<SessionGuard>();
                        if (member == null) {
                          return Scaffold(
                            appBar: AppBar(
                              title: const Text('내 즐겨찾기'),
                              centerTitle: true,
                            ),
                            body: Center(
                              child: auth.memberStatus == MemberLoadStatus.error
                                  ? Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: MovieLogButton(
                                        label: '내 정보 다시 불러오기',
                                        onPressed: () =>
                                            auth.loadMember(force: true),
                                      ),
                                    )
                                  : const CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (guard.accountId != member.email) {
                          return Scaffold(
                            appBar: AppBar(
                              title: Text('내 즐겨찾기'),
                              centerTitle: true,
                            ),
                            body: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return ChangeNotifierProvider<FavoritesViewModel>(
                          key: ValueKey('${member.email}:${guard.generation}'),
                          create: (context) => FavoritesViewModel(
                            favoriteApi: context.read<FavoriteApiService>(),
                            tmdbApi: context.read<TmdbMovieService>(),
                            sessionGuard: guard,
                            accountId: member.email,
                            auth: auth,
                          ),
                          child: FavoritesScreen(
                            onOpenMovie: (movie) async {
                              await context.push(
                                '/movies/${movie.id}',
                                extra: movie,
                              );
                            },
                          ),
                        );
                      },
                    ),
                    GoRoute(
                      path: 'ratings', // /my Route 아래의 자식, root Navigator에 표시
                      parentNavigatorKey: AppRouter.rootNavigatorKey,
                      builder: (context, state) {
                        return ChangeNotifierProvider<MyRatingsViewModel>(
                          create: (context) => MyRatingsViewModel(
                            context.read<RatingApiService>(),
                            context.read<TmdbMovieService>(),
                            context.read<SessionRatingsStore>(),
                            context.read<AuthViewModel>(),
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
}
