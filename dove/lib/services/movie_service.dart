import '../data/mock_movies.dart';
import '../models/movie.dart';

enum MovieLoadMode { success, empty, failure, timeout }

class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;

  @override
  String toString() => 'MovieLoadException: $message';
}

class FakeMovieService {
  const FakeMovieService({
    this.delay = const Duration(seconds: 1),
    this.timeoutDelay = const Duration(seconds: 10),
  });

  final Duration delay;
  final Duration timeoutDelay;

  // TODO(5주차 유저별 평점 조회 API): Future.delayed 기반 Mock을 실제 API 호출로 교체한다.
  Future<List<Movie>> fetchMovies({
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    await Future<void>.delayed(
      mode == MovieLoadMode.timeout ? timeoutDelay : delay,
    );

    return switch (mode) {
      MovieLoadMode.success || MovieLoadMode.timeout => mockMovies,
      MovieLoadMode.empty => const <Movie>[],
      MovieLoadMode.failure => throw const MovieLoadException(
        '영화를 불러오지 못했습니다.',
      ),
    };
  }
}
