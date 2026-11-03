import 'dart:convert';

import 'package:http/http.dart' as http;

const baseUrl = 'http://localhost:8080';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
}

dynamic _handle(http.Response res) {
  final body = jsonDecode(utf8.decode(res.bodyBytes));
  if (res.statusCode == 200) return body;
  throw ApiException(body['message'] ?? '오류가 발생했습니다.');
}

Future<Map<String, dynamic>> checkNickname(String nickname) async {
  final res = await http.get(
    Uri.parse('$baseUrl/members/nickname/${Uri.encodeComponent(nickname)}'),
  );
  return _handle(res);
}

Future<Map<String, dynamic>> checkEmail(String email) async {
  final res = await http.get(
    Uri.parse('$baseUrl/members/email/${Uri.encodeComponent(email)}'),
  );
  return _handle(res);
}

Future<Map<String, dynamic>> getUserRatings(
  int memberId, {
  int page = 0,
  int size = 10,
}) async {
  final uri = Uri.parse('$baseUrl/members/$memberId/ratings')
      .replace(queryParameters: {'page': '$page', 'size': '$size'});
  final res = await http.get(uri);
  return _handle(res);
}
