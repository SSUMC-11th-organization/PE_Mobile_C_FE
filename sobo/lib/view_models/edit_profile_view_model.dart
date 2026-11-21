import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/services/member_api_service.dart';
import 'auth_view_model.dart';

enum EditProfileStatus { idle, saving, success, failure }

class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this._memberApi, this._auth);

  final MemberApiService _memberApi;
  final AuthViewModel _auth;

  EditProfileStatus status = EditProfileStatus.idle;
  String? nicknameError;
  String? message;
  bool _disposed = false;

  String? validateNickname(String value) {
    final nickname = value.trim();
    if (nickname.length < 2 || nickname.length > 12) {
      return '닉네임은 2~12자로 입력해 주세요.';
    }
    return null;
  }

  void clearNicknameError() {
    if (nicknameError == null) return;
    nicknameError = null;
    _notify();
  }

  Future<bool> save(String input) async {
    if (_disposed || status == EditProfileStatus.saving) return false;
    if (_auth.status != AuthStatus.signedIn || _auth.member == null) {
      return false;
    }

    final version = _auth.sessionVersion;
    final nickname = input.trim();
    nicknameError = validateNickname(nickname);
    message = null;

    if (nicknameError != null) {
      _notify();
      return false;
    }

    if (nickname == _auth.member!.nickname) {
      status = EditProfileStatus.success;
      _notify();
      return true;
    }

    status = EditProfileStatus.saving;
    nicknameError = null;
    _notify();

    try {
      final updatedMember = await _memberApi.updateNickname(nickname);
      if (!_isCurrentSession(version)) return false;

      _auth.updateMember(updatedMember);
      status = EditProfileStatus.success;
      _notify();
      return true;
    } on DioException catch (error) {
      if (!_isCurrentSession(version)) return false;

      status = EditProfileStatus.failure;
      final code = apiErrorCode(error);

      if (code == 'AUTH401_2' || code == 'AUTH401_3' || code == 'AUTH401_4') {
        await _auth.expireSession();
        return false;
      }

      if (code == 'MEMBER409_1') {
        nicknameError = '이미 사용 중인 닉네임이에요.';
      } else if (code == 'COMMON400') {
        nicknameError = apiErrorMessage(error) ?? '닉네임 형식을 확인해 주세요.';
      } else if (code == 'MEMBER404_1') {
        message = '회원 정보를 찾을 수 없어요.';
      } else {
        message = '네트워크 상태를 확인하고 다시 시도해 주세요.';
      }
    } catch (_) {
      if (!_isCurrentSession(version)) return false;

      status = EditProfileStatus.failure;
      message = '알 수 없는 오류가 발생했어요.';
    }

    _notify();
    return false;
  }

  bool _isCurrentSession(int version) {
    return !_disposed &&
        version == _auth.sessionVersion &&
        _auth.status == AuthStatus.signedIn;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
