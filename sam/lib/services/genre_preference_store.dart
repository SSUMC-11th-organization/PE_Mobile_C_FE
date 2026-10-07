// 마지막으로 선택한 장르 저장소 (앱 실행 중 메모리에 유지)
class GenrePreferenceStore {
  const GenrePreferenceStore();

  static String? _lastGenre;

  String? load() => _lastGenre;

  void save(String genre) => _lastGenre = genre;

  void clear() => _lastGenre = null;
}
