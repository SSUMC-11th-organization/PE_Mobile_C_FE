// 평점 DTO·서비스·오류 문구 테스트
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_request.dart';
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

  test('fetchMyRatings requests /v7/members/{id}/ratings', () async {
    final adapter = FakeMovieLogAdapter((_) => (200, sampleRatingsJson()));

    final ratings = await fakeRatingService(adapter).fetchMyRatings(1);

    expect(adapter.requests.single.path, '/v7/members/1/ratings');
    expect(ratings.map((r) => r.movieId), [13, 550]);
  });

  test(
    'writeMyRatingsErrorMessage distinguishes 400, 404 and others',
    () async {
      Future<String> messageFor(int status) async {
        final adapter = FakeMovieLogAdapter(
          (_) => (status, {'statusCode': status}),
        );
        final error = await fakeRatingService(adapter)
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

  group('v7 쓰기 요청', () {
    test('createRating posts to /v7/ratings and parses the result', () async {
      final adapter = FakeMovieLogAdapter(
        (_) => (201, ratingResultJson(movieId: 550, score: 5, comment: '최고')),
      );

      final rating = await fakeRatingService(adapter).createRating(
        const CreateRatingRequest(movieId: 550, score: 5, comment: '최고'),
      );

      final sent = adapter.requests.single;
      expect(sent.method, 'POST');
      expect(sent.path, '/v7/ratings');
      expect(sent.data, {'movieId': 550, 'score': 5, 'comment': '최고'});
      expect(rating.movieId, 550);
      expect(rating.score, 5);
    });

    test('updateRating always sends score and comment together', () async {
      final adapter = FakeMovieLogAdapter((_) => (200, ratingResultJson()));

      await fakeRatingService(adapter).updateRating(ratingId: 3, score: 4);

      final sent = adapter.requests.single;
      expect(sent.method, 'PATCH');
      expect(sent.path, '/v7/ratings/3');
      // comment를 비워도 키를 빼지 않고 null로 보냄 (전체 교체)
      expect(sent.data, {'score': 4, 'comment': null});
    });

    test('deleteRating accepts 200 and rejects other success codes', () async {
      final ok = FakeMovieLogAdapter((_) => (200, {}));
      await fakeRatingService(ok).deleteRating(3);
      expect(ok.requests.single.path, '/v7/ratings/3');

      final noContent = FakeMovieLogAdapter((_) => (204, {}));
      expect(
        fakeRatingService(noContent).deleteRating(3),
        throwsA(isA<StateError>()),
      );
    });

    test('parse helpers reject unexpected shapes', () {
      expect(() => parseRatingResult([]), throwsStateError);
      expect(
        () => parseRatingResult({
          'isSuccess': true,
          'code': 'COMMON200',
          'message': '성공',
        }),
        throwsStateError,
      );
      expect(() => parseRatingList({'result': []}), throwsStateError);
      expect(parseRatingList(sampleRatingsJson()), hasLength(2));
    });
  });
}
