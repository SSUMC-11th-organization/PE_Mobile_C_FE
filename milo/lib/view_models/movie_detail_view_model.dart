import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';

enum MovieDetailLoadStatus { idle, loading, success, error }

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._service, this.movieId);

  final TmdbMovieService _service;
  final int movieId;

  TmdbMovieDetailDto? movie;
  MovieDetailLoadStatus status = MovieDetailLoadStatus.idle;
  String message = '';
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    status = MovieDetailLoadStatus.loading;
    notifyListeners();

    try {
      movie = await _service.fetchMovieDetail(movieId);
      status = MovieDetailLoadStatus.success;
    } on DioException catch (e) {
      status = MovieDetailLoadStatus.error;
      message = e.response?.statusCode == 404
          ? '영화 정보를 찾을 수 없어요.'
          : '영화 정보를 불러오지 못했어요.';
    } catch (_) {
      status = MovieDetailLoadStatus.error;
      message = '알 수 없는 오류가 발생했어요.';
    }

    if (!_disposed) notifyListeners();
  }
}
