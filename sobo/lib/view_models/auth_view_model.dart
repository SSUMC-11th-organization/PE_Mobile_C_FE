// 로그인 상태 관리 (로그인·세션 복원·내 정보·세션 정리)
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/login_models.dart';
import '../data/models/member_info.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';
import '../data/services/token_storage.dart';

enum AuthStatus {
  initializing,
  signedOut,
  authenticating,
  signedIn,
  retryRequired,
}

enum MemberLoadStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authApi, this._memberApi, this._storage);

  final AuthApiService _authApi;
  final MemberApiService _memberApi;
  final TokenStorage _storage;

  AuthStatus status = AuthStatus.initializing;
  MemberInfo? member;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  String? message;

  int _sessionVersion = 0;
  int get sessionVersion => _sessionVersion;

  bool sessionExpired = false;
  bool storageCleanupInProgress = false;
  bool _disposed = false;
  Future<void>? _tokenWrite;

  bool _isCurrent(int version) => !_disposed && version == _sessionVersion;

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    if (_disposed ||
        storageCleanupInProgress ||
        status == AuthStatus.authenticating) {
      return;
    }

    status = AuthStatus.authenticating;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = false;
    message = null;

    final version = ++_sessionVersion;
    _notify();

    try {
      final result = await _authApi.login(
        LoginRequest(email: email, password: password),
      );

      if (!_isCurrent(version)) return;

      final writing = _storage.saveAccessToken(result.accessToken);
      _tokenWrite = writing;

      try {
        await writing;
      } finally {
        if (identical(_tokenWrite, writing)) {
          _tokenWrite = null;
        }
      }

      if (!_isCurrent(version)) return;

      // 신규 로그인: 토큰 저장 → signedIn → MainScreen.loadMember()
      // 앱 재시작: restoreSession()에서 GET me 검증 후 signedIn
      status = AuthStatus.signedIn;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;

      status = AuthStatus.signedOut;
      message = apiErrorCode(error) == 'AUTH401_1'
          ? '이메일 또는 비밀번호를 확인해 주세요.'
          : '로그인 요청에 실패했어요. 잠시 후 다시 시도해 주세요.';
    } catch (_) {
      if (!_isCurrent(version)) return;

      status = AuthStatus.signedOut;
      message = '로그인 정보를 안전하게 저장하지 못했어요.';
    }

    _notify();
  }

  Future<void> loadMember({bool force = false}) async {
    if (_disposed || status != AuthStatus.signedIn) return;
    if (memberStatus == MemberLoadStatus.loading) return;
    if (member != null && !force) return;

    final version = _sessionVersion;

    memberStatus = MemberLoadStatus.loading;
    _notify();

    try {
      final me = await _memberApi.fetchMe();

      if (!_isCurrent(version)) return;

      member = me;
      memberStatus = MemberLoadStatus.success;
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;

      final code = apiErrorCode(error);

      if (code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4') {
        await _clearCurrentSession();
        return;
      }

      // 네트워크 오류는 로그아웃시키지 않고 재시도할 수 있게 둠
      memberStatus = MemberLoadStatus.error;
      message = '내 정보를 불러오지 못했어요.';
    } catch (_) {
      if (!_isCurrent(version)) return;

      // 응답 파싱 등 예상하지 못한 오류
      memberStatus = MemberLoadStatus.error;
      message = '내 정보를 불러오지 못했어요.';
    }

    _notify();
  }

  Future<void> restoreSession() async {
    if (storageCleanupInProgress || _disposed) return;

    final version = ++_sessionVersion;

    status = AuthStatus.initializing;
    message = null;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    _notify();

    try {
      final token = await _storage.readAccessToken();

      if (!_isCurrent(version)) return;

      if (token == null || token.isEmpty) {
        status = AuthStatus.signedOut;
      } else {
        // 보호용 Dio가 저장된 토큰을 Authorization 헤더에 붙여 요청
        final verifiedMember = await _memberApi.fetchMe();

        if (!_isCurrent(version)) return;

        member = verifiedMember;
        memberStatus = MemberLoadStatus.success;
        status = AuthStatus.signedIn;
      }
    } on DioException catch (error) {
      if (!_isCurrent(version)) return;

      final code = apiErrorCode(error);

      if (code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4') {
        await _clearCurrentSession(expired: true);
        return;
      }

      // 네트워크 오류만으로 저장된 토큰을 삭제하지 않음
      status = AuthStatus.retryRequired;
      message = '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.';
    } catch (_) {
      if (!_isCurrent(version)) return;

      status = AuthStatus.retryRequired;
      message = '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.';
    }

    if (_isCurrent(version)) {
      _notify();
    }
  }

  // 프로필 수정 성공 응답으로 메모리의 내 정보를 교체
  void updateMember(MemberInfo updated) {
    if (_disposed || status != AuthStatus.signedIn) return;

    member = updated;
    memberStatus = MemberLoadStatus.success;
    _notify();
  }

  // 직접 로그아웃: 만료 안내 Snackbar는 표시하지 않음
  Future<void> logout() => _clearCurrentSession(expired: false);

  // 다른 ViewModel에서 인증 오류를 받았을 때 호출
  Future<void> expireSession() => _clearCurrentSession(expired: true);

  // 로그인 화면에서 세션 만료 안내를 표시한 뒤 호출
  void consumeSessionExpired() {
    sessionExpired = false;
  }

  Future<void> _clearCurrentSession({bool expired = true}) async {
    if (_disposed || storageCleanupInProgress) return;

    final version = ++_sessionVersion;

    storageCleanupInProgress = true;
    member = null;
    memberStatus = MemberLoadStatus.idle;
    sessionExpired = expired;
    status = AuthStatus.signedOut;
    message = null;
    _notify();

    try {
      // 진행 중인 토큰 저장이 끝난 뒤 삭제
      try {
        await _tokenWrite;
      } catch (_) {
        // 저장이 실패했어도 토큰 삭제는 시도
      }

      await _storage.deleteAccessToken();
    } catch (_) {
      if (_isCurrent(version)) {
        message = '저장된 인증 정보를 지우지 못했어요. 앱 재실행 전에 저장소 상태를 확인해 주세요.';
      }
    } finally {
      storageCleanupInProgress = false;

      if (_isCurrent(version)) {
        _notify();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionVersion++;
    super.dispose();
  }
}
