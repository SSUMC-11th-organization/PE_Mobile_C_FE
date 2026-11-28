import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/map_bounded.dart';
import '../core/utils/safe_notify.dart';
import '../data/models/favorite_list_item.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'auth_view_model.dart';
import 'load_phase.dart';

class FavoritesViewModel extends ChangeNotifier with SafeNotify {
  FavoritesViewModel({
    required this.favoriteApi,
    required this.tmdbApi,
    required this.sessionGuard,
    required this.accountId,
    required this.auth,
    this.enrichmentConcurrency = 5,
  });

  final FavoriteApiService favoriteApi;
  final TmdbMovieService tmdbApi;
  final SessionGuard sessionGuard;
  final String accountId;
  final AuthViewModel auth;
  final int enrichmentConcurrency;

  LoadPhase phase = LoadPhase.idle;
  List<FavoriteListItem> items = const [];
  String? errorMessage;
  int _refreshGeneration = 0;
  final Set<int> loadingMovieIds = {};

  Future<void> refresh() async {
    final sessionGeneration = sessionGuard.generation;
    if (!sessionGuard.isCurrent(sessionGeneration, accountId) || isDisposed) {
      return;
    }
    final refreshGeneration = ++_refreshGeneration;
    phase = LoadPhase.loading;
    errorMessage = null;
    loadingMovieIds.clear();
    notifyIfAlive();

    try {
      final favorites = await favoriteApi.fetchMyFavorites();
      if (!_isCurrent(sessionGeneration, refreshGeneration)) return;

      final enriched = await mapBounded(favorites, enrichmentConcurrency, (
        favorite,
      ) async {
        try {
          final movie = await tmdbApi.fetchMovieDetail(favorite.movieId);
          return FavoriteListItem(favorite: favorite, movie: movie);
        } catch (_) {
          return FavoriteListItem(
            favorite: favorite,
            errorMessage: '영화 정보를 불러오지 못했습니다.',
          );
        }
      });
      if (!_isCurrent(sessionGeneration, refreshGeneration)) return;

      items = enriched;
      phase = items.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } on DioException catch (error) {
      if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
      if (_isExpired(error)) {
        await auth.expireSession();
        return;
      }
      phase = LoadPhase.error;
      errorMessage = '내 즐겨찾기 목록을 불러오지 못했습니다.';
    } catch (_) {
      if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
      phase = LoadPhase.error;
      errorMessage = '내 즐겨찾기 목록을 불러오지 못했습니다.';
    } finally {
      if (_isCurrent(sessionGeneration, refreshGeneration)) notifyIfAlive();
    }
  }

  Future<void> retryMovie(int movieId) async {
    if (isDisposed || loadingMovieIds.contains(movieId)) return;
    final sessionGeneration = sessionGuard.generation;
    final refreshGeneration = _refreshGeneration;
    if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
    final index = items.indexWhere((item) => item.favorite.movieId == movieId);
    if (index < 0) return;

    loadingMovieIds.add(movieId);
    notifyIfAlive();
    try {
      final movie = await tmdbApi.fetchMovieDetail(movieId);
      if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
      final updated = [...items];
      updated[index] = FavoriteListItem(
        favorite: updated[index].favorite,
        movie: movie,
      );
      items = updated;
    } catch (_) {
      if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
      final updated = [...items];
      updated[index] = FavoriteListItem(
        favorite: updated[index].favorite,
        errorMessage: '영화 정보를 불러오지 못했습니다.',
      );
      items = updated;
    } finally {
      if (_isCurrent(sessionGeneration, refreshGeneration)) {
        loadingMovieIds.remove(movieId);
        notifyIfAlive();
      }
    }
  }

  bool _isExpired(DioException error) {
    final code = apiErrorCode(error);
    return code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
  }

  bool _isCurrent(int sessionGeneration, int refreshGeneration) =>
      !isDisposed &&
      sessionGuard.isCurrent(sessionGeneration, accountId) &&
      refreshGeneration == _refreshGeneration;
}
