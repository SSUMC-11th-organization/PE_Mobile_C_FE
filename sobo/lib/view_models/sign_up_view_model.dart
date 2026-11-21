import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/models/create_member_request.dart';
import '../services/sign_up_service.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

enum SubmitStatus { idle, submitting, success, error }

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);

  final SignUpService _service;
  bool _disposed = false;

  // 회원가입 제출 상태
  SubmitStatus submitStatus = SubmitStatus.idle;
  int? createdMemberId;
  String? passwordErrorText;
  String? snackbarMessage;

  // 닉네임 중복 확인 상태
  CheckStatus nicknameCheckStatus = CheckStatus.idle;
  String? nicknameErrorText;
  String? _duplicatedNickname;
  String _currentNickname = '';
  int _nicknameRequestVersion = 0;

  // 이메일 중복 확인 상태
  CheckStatus emailCheckStatus = CheckStatus.idle;
  String? emailErrorText;
  String? _duplicatedEmail;
  String _currentEmail = '';
  int _emailRequestVersion = 0;

  bool get canCheckNickname =>
      nicknameCheckStatus != CheckStatus.checking &&
          nicknameCheckStatus != CheckStatus.duplicated;

  bool get canCheckEmail =>
      emailCheckStatus != CheckStatus.checking &&
          emailCheckStatus != CheckStatus.duplicated;

  void onNicknameChanged(String value) {
    snackbarMessage = null;
    _currentNickname = value.trim();
    _nicknameRequestVersion++;

    if (_duplicatedNickname != null &&
        _currentNickname == _duplicatedNickname) {
      nicknameCheckStatus = CheckStatus.duplicated;
      nicknameErrorText = '이미 사용 중인 닉네임입니다.';
    } else {
      nicknameCheckStatus = CheckStatus.idle;
      nicknameErrorText = null;
    }

    if (!_disposed) notifyListeners();
  }

  void onEmailChanged(String value) {
    snackbarMessage = null;
    _currentEmail = value.trim();
    _emailRequestVersion++;

    if (_duplicatedEmail != null && _currentEmail == _duplicatedEmail) {
      emailCheckStatus = CheckStatus.duplicated;
      emailErrorText = '이미 사용 중인 이메일입니다.';
    } else {
      emailCheckStatus = CheckStatus.idle;
      emailErrorText = null;
    }

    if (!_disposed) notifyListeners();
  }

  void onPasswordChanged() {
    passwordErrorText = null;
    if (!_disposed) notifyListeners();
  }

  Future<void> checkNickname(String value) async {
    final requested = value.trim();

    if (_disposed ||
        requested.isEmpty ||
        requested != _currentNickname ||
        !canCheckNickname) {
      return;
    }

    final version = ++_nicknameRequestVersion;
    nicknameCheckStatus = CheckStatus.checking;
    nicknameErrorText = null;
    notifyListeners();

    try {
      final available = await _service.checkNickname(requested);

      if (_disposed || version != _nicknameRequestVersion) return;

      nicknameCheckStatus =
      available ? CheckStatus.available : CheckStatus.duplicated;
      nicknameErrorText = available ? null : '이미 사용 중인 닉네임입니다.';

      if (!available) _duplicatedNickname = requested;
    } on DioException {
      if (_disposed || version != _nicknameRequestVersion) return;

      nicknameCheckStatus = CheckStatus.error;
      nicknameErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }

    if (!_disposed && version == _nicknameRequestVersion) {
      notifyListeners();
    }
  }

  Future<void> checkEmail(String value) async {
    final requested = value.trim();

    if (_disposed ||
        requested.isEmpty ||
        requested != _currentEmail ||
        !canCheckEmail) {
      return;
    }

    final version = ++_emailRequestVersion;
    emailCheckStatus = CheckStatus.checking;
    emailErrorText = null;
    notifyListeners();

    try {
      final available = await _service.checkEmail(requested);

      if (_disposed || version != _emailRequestVersion) return;

      emailCheckStatus =
      available ? CheckStatus.available : CheckStatus.duplicated;
      emailErrorText = available ? null : '이미 사용 중인 이메일입니다.';

      if (!available) _duplicatedEmail = requested;
    } on DioException {
      if (_disposed || version != _emailRequestVersion) return;

      emailCheckStatus = CheckStatus.error;
      emailErrorText = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }

    if (!_disposed && version == _emailRequestVersion) {
      notifyListeners();
    }
  }

  Future<void> submit(CreateMemberRequest request) async {
    if (_disposed || submitStatus == SubmitStatus.submitting) return;

    submitStatus = SubmitStatus.submitting;
    createdMemberId = null;
    passwordErrorText = null;
    snackbarMessage = null;
    notifyListeners();

    try {
      final response = await _service.signUp(request);
      if (_disposed) return;

      final id = response.result?.memberId;
      if (id == null) {
        throw StateError('회원가입 결과에 memberId가 없습니다.');
      }

      createdMemberId = id;
      submitStatus = SubmitStatus.success;
    } on DioException catch (error) {
      if (_disposed) return;

      submitStatus = SubmitStatus.error;
      final message = writeSignUpErrorMessage(error);

      if (error.response?.statusCode == 400 &&
          message.contains('비밀번호')) {
        passwordErrorText = message;
      } else {
        snackbarMessage = message;
      }
    } on StateError {
      if (_disposed) return;

      submitStatus = SubmitStatus.error;
      snackbarMessage =
      '가입 결과를 확인하지 못했습니다. 새 요청 전에 서버 상태를 확인해 주세요.';
    }

    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nicknameRequestVersion++;
    _emailRequestVersion++;
    super.dispose();
  }
}