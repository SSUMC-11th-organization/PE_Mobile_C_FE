import 'dart:convert';

import 'package:http/http.dart' as http;

class MemberApiService {
  static const _baseUrl = 'http://localhost:8080';

  static Future<dynamic> _get(String path) async {
    final response = await http
        .get(Uri.parse('$_baseUrl$path'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static Future<bool> checkNickname(String nickname) async {
    final data = await _get(
      '/members/nickname/${Uri.encodeComponent(nickname)}',
    );

    return data['available'] as bool;
  }

  static Future<bool> checkEmail(String email) async {
    final data = await _get(
      '/members/email/${Uri.encodeComponent(email)}',
    );

    return data['available'] as bool;
  }

  static Future<List<Map<String, dynamic>>> getRatings(
      int memberId,
      ) async {
    final data = await _get('/members/$memberId/ratings');

    return (data as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}