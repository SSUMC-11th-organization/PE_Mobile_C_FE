import 'package:movielog/data/movie_sort_option.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SortPreference {
  SortPreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _selectedSortKey = 'selected_sort';

  final SharedPreferencesAsync _preferences;

  Future<MovieSortOption> read() async {
    final name = await _preferences.getString(_selectedSortKey);
    return MovieSortOption.values.asNameMap()[name] ?? MovieSortOption.none;
  }

  Future<void> save(MovieSortOption option) async {
    await _preferences.setString(_selectedSortKey, option.name);
  }

  Future<void> clear() async {
    await _preferences.remove(_selectedSortKey);
  }
}
