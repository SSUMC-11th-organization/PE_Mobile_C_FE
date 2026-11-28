import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/services/tmdb_movie_service.dart';

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service);

  final TmdbMovieService _service;
  List<TmdbGenreDto> genres = const [];
  int? selectedGenreId;
  bool _isLoadingGenres = false;
  String? genreError;
  bool _disposed = false;

  Future<void> loadGenres({bool force = false}) async {
    if (_disposed || _isLoadingGenres || (genres.isNotEmpty && !force)) return;
    _isLoadingGenres = true;
    genreError = null;
    notifyListeners();
    try {
      final result = await _service.fetchGenres();
      if (!_disposed) genres = result;
    } catch (_) {
      if (_disposed) return;
      genreError = '장르 목록을 불러오지 못했어요.';
    } finally {
      if (!_disposed) {
        _isLoadingGenres = false;
        notifyListeners();
      }
    }
  }

  void selectGenre(int? genreId) {
    if (_disposed || selectedGenreId == genreId) return;
    selectedGenreId = genreId;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
