// 이번 로그인 세션에서 등록 응답으로 받은 평점 모음
//
// v7 로그인·내 정보 응답에는 memberId가 없고 토큰 기반 '내 평점 목록 GET'도 없습니다.
// 그래서 등록 result로 받은 평점만 현재 세션에서 수정·삭제하고,
// 로그아웃·만료·다른 계정 로그인(sessionVersion 변경) 때 비웁니다.
import 'package:flutter/foundation.dart';

import '../data/models/rating_dto.dart';
import 'auth_view_model.dart';

class SessionRatingsStore extends ChangeNotifier {
  SessionRatingsStore(this._auth) : _boundVersion = _auth.sessionVersion {
    _auth.addListener(_onAuthChanged);
  }

  final AuthViewModel _auth;
  int _boundVersion;
  final List<RatingDto> _ratings = [];

  // 최근에 등록한 평점이 위로 오도록 보관합니다.
  List<RatingDto> get ratings => List.unmodifiable(_ratings);

  void _onAuthChanged() {
    if (_auth.sessionVersion == _boundVersion) return;
    _boundVersion = _auth.sessionVersion;
    if (_ratings.isEmpty) return;
    _ratings.clear();
    notifyListeners();
  }

  // 등록 응답의 평점을 추가합니다. 같은 ratingId가 있으면 교체합니다.
  void add(RatingDto rating) {
    _ratings.removeWhere((r) => r.ratingId == rating.ratingId);
    _ratings.insert(0, rating);
    notifyListeners();
  }

  // 수정 응답의 평점으로 같은 ratingId 항목을 교체합니다.
  void replace(RatingDto rating) {
    final index = _ratings.indexWhere((r) => r.ratingId == rating.ratingId);
    if (index < 0) return;
    _ratings[index] = rating;
    notifyListeners();
  }

  void remove(int ratingId) {
    final before = _ratings.length;
    _ratings.removeWhere((r) => r.ratingId == ratingId);
    if (_ratings.length != before) notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
