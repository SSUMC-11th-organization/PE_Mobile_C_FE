import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/core/network/movie_log_client.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/core/session/auth_session_bridge.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/movie_record_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/models/login_models.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/storage/token_storage.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:provider/provider.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = SecureTokenStorage(const FlutterSecureStorage());
    final publicClient = createMovieLogClient(); // Interceptor 없음
    final authClient = createAuthMovieLogClient(tokenStorage); // Interceptor 등록

    return MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        // 공개 Client
        Provider<AuthApiService>(create: (_) => AuthApiService(publicClient)),
        Provider<SignUpService>(create: (_) => SignUpService(publicClient)),
        // 보호 Client (RatingApiService는 공개 조회용 publicClient도 함께 받음)
        Provider<MemberApiService>(create: (_) => MemberApiService(authClient)),
        Provider<RatingApiService>(
          create: (_) => RatingApiService(publicClient, authClient),
        ),
        // authClient는 8주차에서 만든 보호용 Dio입니다. 새로 만들지 않고 기존 인스턴스를 사용합니다.
        Provider<FavoriteApiService>(
          create: (_) => FavoriteApiService(authClient),
        ),
        Provider<MovieRecordApiService>(
          create: (_) => MovieRecordApiService(authClient),
        ),
        // 학습용 현재 회원 (가입 결과의 memberId를 보관)
        ChangeNotifierProvider<LearningMemberSession>(
          create: (_) => LearningMemberSession(),
        ),
        // Service를 주입받는 ViewModel
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthApiService>(),
            context.read<MemberApiService>(),
            context.read<TokenStorage>(),
          ),
        ),
        // AuthViewModel을 읽으므로 반드시 그 뒤에 둡니다.
        Provider<AuthSessionBridge>(
          create: (context) {
            final auth = context.read<AuthViewModel>();
            return AuthSessionBridge(
              authSignals: auth,
              sessionVersion: () => auth.sessionVersion,
              verifiedEmail: () => auth.status == AuthStatus.signedIn
                  ? auth.member?.email
                  : null,
            );
          },
          dispose: (_, bridge) => bridge.dispose(),
        ),
        Provider<SessionGuard>(
          create: (context) => context.read<AuthSessionBridge>().guard,
        ),
      ],
      child: const _MovieLogRouterApp(), // 뒤 절의 Stateful Router 호스트를 사용합니다.
    );
  }
}

class _MovieLogRouterApp extends StatefulWidget {
  const _MovieLogRouterApp();

  @override
  State<_MovieLogRouterApp> createState() => _MovieLogRouterAppState();
}

class _MovieLogRouterAppState extends State<_MovieLogRouterApp> {
  late final GoRouter _router;
  late final AuthViewModel _authViewModel;
  late final LearningMemberSession _learningSession;
  AuthStatus _previousStatus = AuthStatus.initializing;

  void _clearLearningSessionOnSignOut() {
    final current = _authViewModel.status;
    if (_previousStatus == AuthStatus.signedIn &&
        current == AuthStatus.signedOut) {
      _learningSession.clear();
    }
    _previousStatus = current;
  }

  @override
  void initState() {
    super.initState();
    _authViewModel = context.read<AuthViewModel>();
    _learningSession = context.read<LearningMemberSession>();
    _authViewModel.addListener(_clearLearningSessionOnSignOut);
    _router = AppRouter.createRouter(_authViewModel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _authViewModel.restoreSession();
    }); // 첫 build 이후 세션 복원을 시작합니다.
  }

  @override
  void dispose() {
    _authViewModel.removeListener(_clearLearningSessionOnSignOut);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
