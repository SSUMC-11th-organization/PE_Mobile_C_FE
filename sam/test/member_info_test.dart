// 내 정보 응답 파싱 테스트
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/member_info.dart';

void main() {
  test('parses the member from a CommonResponse', () {
    final member = parseMemberInfo({
      'isSuccess': true,
      'code': 'COMMON200',
      'message': '조회 성공',
      'result': {
        'email': 'movie@example.com',
        'nickname': '무비러버',
        'createdAt': '2026-11-18T10:30:00',
      },
    });

    expect(member.email, 'movie@example.com');
    expect(member.nickname, '무비러버');
    expect(member.createdAt, DateTime(2026, 11, 18, 10, 30));
  });

  test('a body that is not a map is a StateError', () {
    expect(() => parseMemberInfo('oops'), throwsStateError);
    expect(() => parseMemberInfo(null), throwsStateError);
  });

  test('a success without result is a StateError', () {
    expect(
      () => parseMemberInfo({
        'isSuccess': true,
        'code': 'COMMON200',
        'message': '조회 성공',
      }),
      throwsStateError,
    );
  });
}
