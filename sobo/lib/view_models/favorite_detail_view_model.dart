import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/safe_notify.dart';
import '../data/services/favorite_api_service.dart';
import 'auth_view_model.dart';

class FavoriteDetailViewModel extends ChangeNotifier with SafeNotify {
  FavoriteDetailViewModel({
    required this.movieId,
    required this.favoriteApi,
    required this.sessionGuard,
    required this.accountId,
    required this.auth,
  });

  final int movieId;
  final FavoriteApiService favoriteApi;
  final SessionGuard sessionGuard;
  final String accountId;
  final AuthViewModel auth;

  bool isFavorite = false;
  bool hasLoadedStatus = false;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  bool _current(int generation) =>
      !isDisposed && sessionGuard.isCurrent(generation, accountId);

  Future<void> load() async {
    if (isLoading || isSaving || isDisposed) return;
    final generation = sessionGuard.generation;
    if (!_current(generation)) return;

    isLoading = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      final result = await favoriteApi.checkFavorite(movieId: movieId);
      if (!_current(generation)) return;
      isFavorite = result.isFavorite;
      hasLoadedStatus = true;
    } on DioException catch (error) {
      if (!_current(generation)) return;
      if (_isExpired(error)) {
        await auth.expireSession();
        return;
      }
      errorMessage = _errorText(error, loading: true);
    } catch (_) {
      if (!_current(generation)) return;
      errorMessage = '즐겨찾기 여부를 확인하지 못했습니다.';
    } finally {
      if (_current(generation)) {
        isLoading = false;
        notifyIfAlive();
      }
    }
  }

  Future<bool> toggle() async {
    if (isSaving || isLoading || !hasLoadedStatus || isDisposed) return false;
    final generation = sessionGuard.generation;
    if (!_current(generation)) return false;

    final wasFavorite = isFavorite;
    isSaving = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      if (wasFavorite) {
        await favoriteApi.deleteFavorite(movieId: movieId);
      } else {
        await favoriteApi.addFavorite(movieId: movieId);
      }
      if (!_current(generation)) return false;
      isFavorite = !wasFavorite;
      return true;
    } on DioException catch (error) {
      if (!_current(generation)) return false;
      final code = apiErrorCode(error);
      if (_isExpired(error)) {
        await auth.expireSession();
        return false;
      }

      if (code == 'FAVORITE409_1' || code == 'FAVORITE404_1') {
        try {
          final current = await favoriteApi.checkFavorite(movieId: movieId);
          if (!_current(generation)) return false;
          isFavorite = current.isFavorite;
          hasLoadedStatus = true;
          errorMessage = code == 'FAVORITE409_1'
              ? '이미 즐겨찾기에 등록된 영화라 현재 상태를 다시 확인했어요.'
              : '이미 해제된 영화라 현재 상태를 다시 확인했어요.';
        } on DioException catch (checkError) {
          if (!_current(generation)) return false;
          if (_isExpired(checkError)) {
            await auth.expireSession();
            return false;
          }
          isFavorite = wasFavorite;
          errorMessage = '서버의 즐겨찾기 상태를 다시 확인하지 못했습니다.';
        } catch (_) {
          if (!_current(generation)) return false;
          isFavorite = wasFavorite;
          errorMessage = '서버의 즐겨찾기 상태를 다시 확인하지 못했습니다.';
        }
        return false;
      }

      isFavorite = wasFavorite;
      errorMessage = _errorText(error, loading: false);
      return false;
    } catch (_) {
      if (!_current(generation)) return false;
      isFavorite = wasFavorite;
      errorMessage = wasFavorite ? '즐겨찾기 해제에 실패했습니다.' : '즐겨찾기 등록에 실패했습니다.';
      return false;
    } finally {
      if (_current(generation)) {
        isSaving = false;
        notifyIfAlive();
      }
    }
  }

  bool _isExpired(DioException error) {
    final code = apiErrorCode(error);
    return code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4';
  }

  String _errorText(DioException error, {required bool loading}) {
    switch (apiErrorCode(error)) {
      case 'FAVORITE403_1':
        return '즐겨찾기를 변경할 권한이 없습니다.';
      case 'MEMBER404_1':
        return '회원 정보를 찾을 수 없습니다.';
      case 'FAVORITE409_1':
        return '이미 즐겨찾기에 등록된 영화입니다.';
      case 'FAVORITE404_1':
        return '이미 해제되었거나 즐겨찾기에서 찾을 수 없는 영화입니다.';
      default:
        return loading
            ? '즐겨찾기 여부를 불러오지 못했습니다.'
            : isFavorite
            ? '즐겨찾기 해제에 실패했습니다.'
            : '즐겨찾기 등록에 실패했습니다.';
    }
  }
}
