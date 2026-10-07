import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/mock_movie.dart';
import 'package:movielog/service/fake_movie_service.dart';

void main() {
  const service = FakeMovieService();

  group('FakeMovieService', () {
    test('success 모드는 Mock 영화 목록을 반환한다', () async {
      final result = await service.fetchMovies(mode: MovieLoadMode.success);

      expect(result, isNotEmpty);
      expect(result, movies);
    });

    // TODO: empty  → 빈 목록
    test('empty 모드는 빈 목록을 반환한다', () async {
      final result = await service.fetchMovies(mode: MovieLoadMode.empty);

      expect(result, isEmpty);
    });

    // TODO: failure → MovieLoadException을 던진다
    test('failure 모드는 MovieLoadException을 던진다', () async {
      await expectLater(
        service.fetchMovies(mode: MovieLoadMode.failure),
        throwsA(isA<MovieLoadException>()),
      );
    });

    // TODO: timeout → TimeoutException을 던진다
    test('timeout 모드는 TimeoutException을 던진다', () async {
      await expectLater(
        service.fetchMovies(mode: MovieLoadMode.timeout),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}
