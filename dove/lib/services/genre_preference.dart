import 'package:shared_preferences/shared_preferences.dart';

class GenrePreference {
  GenrePreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const selectedGenreKey = 'selected_genre';
  static const allGenres = '전체';

  final SharedPreferencesAsync _preferences;

  Future<String> read() async {
    return await _preferences.getString(selectedGenreKey) ?? allGenres;
  }

  Future<void> save(String genre) async {
    await _preferences.setString(selectedGenreKey, genre);
  }

  Future<void> clear() async {
    await _preferences.remove(selectedGenreKey);
  }
}
