import 'package:dio/dio.dart'; // ★ 추가
import 'package:flutter/foundation.dart';
import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/core/utils/map_bounded.dart';
import 'package:movielog/core/utils/safe_notify.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/models/favorite_list_item.dart';
import 'package:movielog/view_models/load_phase.dart';

class FavoritesViewModel extends ChangeNotifier with SafeNotify {
  FavoritesViewModel({
    required this.favoriteApi,
    required this.tmdbApi,
    required this.sessionGuard,
    required this.accountId,
    this.enrichmentConcurrency = 5,
    this.onSessionExpired,
  });

  final FavoriteApiService favoriteApi;
  final TmdbMovieService tmdbApi;
  final SessionGuard sessionGuard;
  final String accountId;
  final int enrichmentConcurrency;
  final Future<void> Function()? onSessionExpired;

  LoadPhase phase = LoadPhase.idle;
  List<FavoriteListItem> items = const [];
  String? errorMessage;
  int _refreshGeneration = 0;

  bool _isSessionExpired(DioException e) {
    final code = apiErrorCode(e);
    return code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
  }

  // 즐겨찾기 목록을 다시 조회하고 TMDB 영화 정보를 최대 5개씩 보충합니다.
  Future<void> refresh() async {
    final sessionGeneration = sessionGuard.generation;
    if (!sessionGuard.isCurrent(sessionGeneration, accountId) || isDisposed) {
      return;
    }
    final refreshGeneration = ++_refreshGeneration;
    phase = LoadPhase.loading;
    errorMessage = null;
    notifyIfAlive();
    try {
      final favorites = await favoriteApi.fetchMyFavorites();
      if (!sessionGuard.isCurrent(sessionGeneration, accountId) ||
          refreshGeneration != _refreshGeneration ||
          isDisposed) {
        return;
      }
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
      if (!sessionGuard.isCurrent(sessionGeneration, accountId) ||
          refreshGeneration != _refreshGeneration ||
          isDisposed) {
        return;
      }
      items = enriched;
      phase = items.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } on DioException catch (error) {
      if (!sessionGuard.isCurrent(sessionGeneration, accountId) ||
          refreshGeneration != _refreshGeneration ||
          isDisposed) {
        return;
      }
      if (_isSessionExpired(error)) {
        await onSessionExpired?.call(); // 세션 정리 + 로그인 화면 이동
        return;
      }
      phase = LoadPhase.error;
      errorMessage = '내 즐겨찾기 목록을 불러오지 못했습니다.';
    } catch (_) {
      if (!sessionGuard.isCurrent(sessionGeneration, accountId) ||
          refreshGeneration != _refreshGeneration ||
          isDisposed) {
        return;
      }
      phase = LoadPhase.error;
      errorMessage = '내 즐겨찾기 목록을 불러오지 못했습니다.';
    } finally {
      if (sessionGuard.isCurrent(sessionGeneration, accountId) &&
          refreshGeneration == _refreshGeneration &&
          !isDisposed) {
        notifyIfAlive();
      }
    }
  }
}
