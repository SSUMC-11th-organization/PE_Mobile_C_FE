// 평점 DTO·서비스·오류 문구 테스트
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';

import 'helpers/fake_movielog.dart';

void main() {
  group('RatingDto.fromJson', () {
    test('parses a rating with a comment', () {
      final rating = RatingDto.fromJson(sampleRatingsJson()[1]);

      expect(rating.ratingId, 1);
      expect(rating.movieId, 550);
      expect(rating.score, 5);
      expect(rating.comment, '최고의 영화!');
      expect(
        rating.createdAt.toUtc(),
        DateTime.utc(2026, 11, 3, 19, 0, 9, 148),
      );
    });

    test('keeps comment: null as null', () {
      final rating = RatingDto.fromJson(sampleRatingsJson()[0]);

      expect(rating.comment, isNull);
    });
  });

  test('fetchMyRatings requests /v5/members/{id}/ratings', () async {
    final adapter = FakeMovieLogAdapter((_) => (200, sampleRatingsJson()));

    final ratings = await RatingApiService(fakeDio(adapter)).fetchMyRatings(1);

    expect(adapter.requests.single.path, '/v5/members/1/ratings');
    expect(ratings.map((r) => r.movieId), [13, 550]);
  });

  test(
    'writeMyRatingsErrorMessage distinguishes 400, 404 and others',
    () async {
      Future<String> messageFor(int status) async {
        final adapter = FakeMovieLogAdapter(
          (_) => (status, {'statusCode': status}),
        );
        final error = await RatingApiService(fakeDio(adapter))
            .fetchMyRatings(1)
            .then<Object?>((_) => null, onError: (Object e) => e);
        return writeMyRatingsErrorMessage(error! as DioException);
      }

      expect(await messageFor(400), 'memberId 형식을 다시 확인해 주세요.');
      expect(await messageFor(404), '존재하지 않는 회원입니다.');
      expect(await messageFor(500), '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.');
    },
  );

  test('TmdbMovieDto reads genre ids from a detail response', () {
    final movie = TmdbMovieDto.fromJson(movieDetailJson(550)).toMovie();

    expect(movie.genre, '드라마');
    expect(movie.year, 1999);
  });
}
