// 학습용 현재 회원 ID 보관 (로그인 인증은 아닙니다)
import 'package:flutter/foundation.dart';

class LearningMemberSession extends ChangeNotifier {
  int? memberId;

  void setMemberId(int id) {
    memberId = id;
    notifyListeners();
  }

  void clear() {
    memberId = null;
    notifyListeners();
  }
}
