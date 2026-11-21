// 현재 로그인 세션에서 등록한 평점을 보관합니다.
// 로그인·GET me 응답에 memberId가 없어 토큰만으로 공개 목록 API를 재조회할 수 없으므로,
// 등록 응답을 목록으로 사용합니다. 앱 재시작 뒤 과거 평점을 복원하지는 않습니다.
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

  List<RatingDto> get ratings => List.unmodifiable(_ratings);

  void _onAuthChanged() {
    if (_auth.sessionVersion == _boundVersion) return;
    _boundVersion = _auth.sessionVersion;
    if (_ratings.isEmpty) return;
    _ratings.clear();
    notifyListeners();
  }

  void add(RatingDto rating) {
    _ratings.removeWhere((item) => item.ratingId == rating.ratingId);
    _ratings.insert(0, rating);
    notifyListeners();
  }

  void replace(RatingDto rating) {
    final index = _ratings.indexWhere(
      (item) => item.ratingId == rating.ratingId,
    );
    if (index == -1) return;
    _ratings[index] = rating;
    notifyListeners();
  }

  void remove(int ratingId) {
    final count = _ratings.length;
    _ratings.removeWhere((item) => item.ratingId == ratingId);
    if (_ratings.length != count) notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
