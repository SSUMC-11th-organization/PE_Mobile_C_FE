import 'package:shared_preferences/shared_preferences.dart';

class GenrePreference {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static const String _selectedGenresKey = 'selected_genres';

  // 저장된 장르 읽기. 없으면 전체 선택을 의미하는 빈 목록 반환
  Future<List<String>> read() async {
    return await _preferences.getStringList(_selectedGenresKey) ?? <String>[];
  }

  // 선택한 장르 목록 저장
  Future<void> save(List<String> genres) async {
    await _preferences.setStringList(_selectedGenresKey, genres);
  }

  // 저장된 장르 삭제
  Future<void> clear() async {
    await _preferences.remove(_selectedGenresKey);
  }
}
