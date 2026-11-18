import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/edit_profile_screen.dart';
import 'package:movielog/screens/favorites_screen.dart';
import 'package:movielog/screens/home_screen.dart';
import 'package:movielog/screens/login_screen.dart';
import 'package:movielog/screens/main_screen.dart';
import 'package:movielog/screens/movie_detail_loader.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/screens/movie_search_screen.dart';
import 'package:movielog/screens/my_page_screen.dart';
import 'package:movielog/screens/my_rating_screen.dart';
import 'package:movielog/screens/register_screen.dart';
import 'package:movielog/screens/splash_screen.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/edit_profile_view_model.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';
import 'package:movielog/view_models/favorites_view_model.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:provider/provider.dart';

class AppRouter {
  AppRouter._();

  static final rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthViewModel authViewModel) {
    return GoRouter(
      initialLocation: '/start',
      navigatorKey: rootNavigatorKey,
      refreshListenable: authViewModel, // 인증 상태가 바뀌면 redirect를 다시 실행합니다.
      redirect: (context, state) {
        return authRedirect(authViewModel.status, state.uri.path);
      },
      routes: [
        GoRoute(
          path: '/start', // 스플래시: 토큰 확인 중 / 확인 실패 시 재시도
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
          path: '/login', // 새로 추가하는 로그인 Route
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        // 3주차에서 만든 ShellRoute 구조를 그대로 사용합니다.
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
                return ChangeNotifierProvider<PagedMoviesViewModel>(
                  create: (context) => PagedMoviesViewModel(
                    tmdbApi: context.read<TmdbMovieService>(),
                  )..loadInitial(),
                  child: MovieListScreen(initialGenres: initialGenres),
                );
              },
              routes: [
                GoRoute(
                  path: 'search',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => ChangeNotifierProvider(
                    create: (_) => PagedMoviesViewModel(
                      tmdbApi: context.read<TmdbMovieService>(),
                    ),
                    child: MovieSearchScreen(
                      onOpenMovie: (movie) async {
                        await context.push('/movies/${movie.id}', extra: movie);
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
                      return const Scaffold(
                        body: Center(child: Text('영화 ID가 올바르지 않습니다.')),
                      );
                    }

                    final member = context.watch<AuthViewModel>().member;
                    final guard = context.read<SessionGuard>();

                    // 내 정보가 준비되고 현재 세션과 일치할 때까지 로딩을 보여 줍니다.
                    if (member == null || guard.accountId != member.email) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final extra = state.extra;
                    return ChangeNotifierProvider<FavoriteDetailViewModel>(
                      // 계정이나 세션이 바뀌면 새 ViewModel을 만듭니다.
                      key: ValueKey('${member.email}:${guard.generation}'),
                      create: (_) => FavoriteDetailViewModel(
                        movieId: id,
                        favoriteApi: context.read<FavoriteApiService>(),
                        sessionGuard: guard,
                        accountId: member.email,
                        onSessionExpired: context
                            .read<AuthViewModel>()
                            .expireSession,
                      ),
                      // 기존에 전달하던 인자(extra 등)는 그대로 유지합니다.
                      child: MovieDetailLoader(
                        movieId: id,
                        initialMovie: extra is TmdbMovieDto && extra.id == id
                            ? extra
                            : null,
                      ),
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
                  parentNavigatorKey:
                      rootNavigatorKey, // 하단 NavigationBar를 가립니다.
                  builder: (context, state) {
                    // 7주차: 가입 결과로 저장한 학습용 memberId를 사용합니다.
                    final id = context.read<LearningMemberSession>().memberId;
                    if (id == null) {
                      return Scaffold(
                        appBar: AppBar(
                          centerTitle: true,
                          title: const Text('내가 등록한 평점'),
                        ),
                        body: const Center(child: Text('학습용 회원가입이 필요합니다.')),
                      );
                    }
                    return ChangeNotifierProvider<MyRatingsViewModel>(
                      create: (context) => MyRatingsViewModel(
                        context.read<RatingApiService>(),
                        context.read<TmdbMovieService>(),
                        context.read<AuthViewModel>(), // ← 새로 끼워 넣는 세 번째 인자
                        id, // 기존 세 번째 인자는 네 번째로 이동
                      )..load(),
                      child: const MyRatingsScreen(),
                    );
                  },
                ),
                GoRoute(
                  path: 'favorites',
                  parentNavigatorKey: rootNavigatorKey,
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
                              ? FilledButton(
                                  onPressed: auth.loadMember,
                                  child: const Text('내 정보 다시 조회'),
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
                    return ChangeNotifierProvider(
                      key: ValueKey('${member.email}:${guard.generation}'),
                      create: (_) => FavoritesViewModel(
                        favoriteApi: context.read<FavoriteApiService>(),
                        tmdbApi: context.read<TmdbMovieService>(),
                        sessionGuard: guard,
                        accountId: member.email,
                        onSessionExpired: auth.expireSession,
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
                  path: 'profile/edit', // 최종 경로: /my/profile/edit
                  parentNavigatorKey: rootNavigatorKey,
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
                              ? MovieLogButton(
                                  label: '다시 시도',
                                  onPressed: () => auth.loadMember(force: true),
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
              ],
            ),
          ],
        ),
      ],
    );
  }

  static int indexFromLocation(String path) {
    if (path.startsWith('/movies')) return 1;
    if (path.startsWith('/my')) return 2;
    return 0;
  }
}

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
