// 마지막으로 선택한 장르 저장소 (SharedPreferencesAsync 사용)
import 'package:shared_preferences/shared_preferences.dart';

class GenrePreferenceStore {
  static const _lastGenreIdKey = 'last_selected_genre_id';

  SharedPreferencesAsync? _preferences;

  // 처음 사용할 때 생성
  SharedPreferencesAsync get _prefs =>
      _preferences ??= SharedPreferencesAsync();

  // TMDB 장르 id, '전체'는 null
  Future<int?> load() => _prefs.getInt(_lastGenreIdKey);

  Future<void> save(int? genreId) => genreId == null
      ? _prefs.remove(_lastGenreIdKey)
      : _prefs.setInt(_lastGenreIdKey, genreId);
}
