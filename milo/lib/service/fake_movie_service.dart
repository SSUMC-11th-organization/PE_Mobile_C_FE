import 'dart:async';

import 'package:movielog/data/mock_movie.dart';

enum MovieLoadMode { success, empty, failure, timeout }

class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;
}

class FakeMovieService {
  const FakeMovieService();

  static const _timeLimit = Duration(seconds: 3);
  Future<List<Movie>> fetchMovies({
    MovieLoadMode mode = MovieLoadMode.success,
  }) {
    return _load(mode).timeout(_timeLimit);
  }

  Future<List<Movie>> _load(MovieLoadMode mode) async {
    // TODO(5주차 유저별 평점 조회 API)
    await Future<void>.delayed(
      MovieLoadMode.timeout == mode
          ? const Duration(seconds: 5)
          : const Duration(seconds: 1),
    );

    return switch (mode) {
      MovieLoadMode.success => movies,
      MovieLoadMode.empty => const <Movie>[],
      MovieLoadMode.failure => throw const MovieLoadException(
        '영화를 불러오지 못했습니다.',
      ),
      MovieLoadMode.timeout => throw TimeoutException('로딩 시간을 초과했습니다.'),
    };
  }
}
