import 'package:shared_preferences/shared_preferences.dart';

import '../models/movie_sort.dart';

class SortPreference {
  SortPreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const selectedSortKey = 'selected_sort';

  final SharedPreferencesAsync _preferences;

  Future<MovieSort> read() async {
    return MovieSort.fromName(await _preferences.getString(selectedSortKey));
  }

  Future<void> save(MovieSort sort) async {
    await _preferences.setString(selectedSortKey, sort.name);
  }

  Future<void> clear() async {
    await _preferences.remove(selectedSortKey);
  }
}
