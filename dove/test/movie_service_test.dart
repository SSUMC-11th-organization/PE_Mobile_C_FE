import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/mock_movies.dart';
import 'package:movielog/services/movie_service.dart';

void main() {
  const service = FakeMovieService(delay: Duration(milliseconds: 10));

  test('success 모드는 Mock 영화 목록을 반환한다', () async {
    final movies = await service.fetchMovies();

    expect(movies, mockMovies);
  });

  test('empty 모드는 빈 목록을 반환한다', () async {
    final movies = await service.fetchMovies(mode: MovieLoadMode.empty);

    expect(movies, isEmpty);
  });

  test('failure 모드는 MovieLoadException으로 완료된다', () async {
    expect(
      service.fetchMovies(mode: MovieLoadMode.failure),
      throwsA(isA<MovieLoadException>()),
    );
  });

  test('기본 지연 시간은 800ms 이상이다', () {
    expect(
      const FakeMovieService().delay,
      greaterThanOrEqualTo(const Duration(milliseconds: 800)),
    );
  });

  test('timeout 모드는 지연 후 완료되어 Future.timeout에 걸린다', () async {
    const slow = FakeMovieService(
      delay: Duration(milliseconds: 10),
      timeoutDelay: Duration(milliseconds: 300),
    );

    await expectLater(
      slow
          .fetchMovies(mode: MovieLoadMode.timeout)
          .timeout(const Duration(milliseconds: 50)),
      throwsA(isA<TimeoutException>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
  });
}
