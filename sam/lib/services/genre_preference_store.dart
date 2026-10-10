// 마지막으로 선택한 장르 저장소 (SharedPreferencesAsync 사용)
import 'package:shared_preferences/shared_preferences.dart';

class GenrePreferenceStore {
  static const _lastGenreKey = 'last_selected_genre';

  SharedPreferencesAsync? _preferences;

  // 처음 사용할 때 생성
  SharedPreferencesAsync get _prefs =>
      _preferences ??= SharedPreferencesAsync();

  Future<String?> load() => _prefs.getString(_lastGenreKey);

  Future<void> save(String genre) => _prefs.setString(_lastGenreKey, genre);
}
