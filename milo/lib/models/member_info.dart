import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/view_models/auth_view_model.dart';

MemberInfo parseMemberInfo(Object? data) {
  if (data is! Map<String, dynamic>) throw StateError('내 정보 응답 형식이 올바르지 않습니다.');
  final common = CommonResponse<MemberInfo>.fromJson(
    data,
    (value) => MemberInfo.fromJson(value as Map<String, dynamic>),
  );
  final member = common.result;
  if (member == null) throw StateError('내 정보 result가 없습니다.');
  return member;
}
