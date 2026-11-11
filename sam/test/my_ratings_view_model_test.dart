// 내가 등록한 평점 ViewModel 테스트
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';

import 'helpers/fake_movielog.dart';

void main() {
  late FakeMovieLogAdapter ratingServer;
  late FakeMovieLogAdapter tmdbServer;
  late MyRatingsViewModel viewModel;

  setUp(() {
    ratingServer = FakeMovieLogAdapter((_) => (200, sampleRatingsJson()));
    tmdbServer = FakeMovieLogAdapter((options) {
      final id = int.parse(options.path.split('/').last);
      return (200, movieDetailJson(id));
    });
    viewModel = MyRatingsViewModel(
      RatingApiService(fakeDio(ratingServer)),
      TmdbMovieService(fakeDio(tmdbServer)),
      1, // 학습용 회원 ID
    );
  });

  test('starts idle', () {
    expect(viewModel.status, MyRatingsStatus.idle);
  });

  test('loads ratings for member 1 and fills moviesById', () async {
    final load = viewModel.load();
    expect(viewModel.status, MyRatingsStatus.loading);
    await load;

    expect(ratingServer.requests.single.path, '/v5/members/1/ratings');
    expect(viewModel.status, MyRatingsStatus.success);
    expect(viewModel.ratings, hasLength(2));
    expect(viewModel.moviesById.keys, unorderedEquals([13, 550]));
    expect(viewModel.moviesById[550]!.title, '영화 550');
    expect(viewModel.isLoadingMovies, isFalse);
  });

  test('an empty list becomes empty', () async {
    ratingServer.route = (_) => (200, <Object>[]);
    await viewModel.load();

    expect(viewModel.status, MyRatingsStatus.empty);
    expect(tmdbServer.requests, isEmpty);
  });

  test('a 404 becomes error with a message', () async {
    ratingServer.route = (_) => (404, {'statusCode': 404});
    await viewModel.load();

    expect(viewModel.status, MyRatingsStatus.error);
    expect(viewModel.errorMessage, '존재하지 않는 회원입니다.');
  });

  test('a failed movie lookup keeps the rating list', () async {
    tmdbServer.route = (options) => options.path.endsWith('/13')
        ? (404, {'status_message': 'not found'})
        : (200, movieDetailJson(550));
    await viewModel.load();

    expect(viewModel.status, MyRatingsStatus.success);
    expect(viewModel.moviesById.keys, [550]);
  });

  test('reloading does not refetch cached movies', () async {
    await viewModel.load();
    await viewModel.load();

    expect(tmdbServer.requests, hasLength(2));
  });

  group('수정·삭제', () {
    // 쓰기 요청은 writeRoute로, 목록 GET은 기본 목록으로 응답
    void serve(
      (int, Object) Function(RequestOptions options) writeRoute, {
      int getStatus = 200,
    }) {
      ratingServer.route = (options) => options.method == 'GET'
          ? (getStatus, getStatus == 200 ? sampleRatingsJson() : {})
          : writeRoute(options);
    }

    Map<String, Object> failure(String code, String message) => {
      'isSuccess': false,
      'code': code,
      'message': message,
    };

    test('updateRating sends PATCH and reloads the list', () async {
      serve((_) => (200, {}));
      await viewModel.updateRating(ratingId: 3, score: 4, comment: '좋아요');

      final patch = ratingServer.requests.first;
      expect(patch.method, 'PATCH');
      expect(patch.path, '/v6/members/1/ratings/3');
      expect(patch.data, {'score': 4, 'comment': '좋아요'});
      expect(ratingServer.requests.last.method, 'GET');
      expect(viewModel.status, MyRatingsStatus.success);
      expect(viewModel.refreshWarning, isNull);
    });

    test('a failed write rethrows with the server message', () async {
      serve((_) => (400, failure('COMMON400', '점수는 1~5 사이여야 합니다.')));

      await expectLater(
        viewModel.updateRating(ratingId: 3, score: 4),
        throwsA(isA<DioException>()),
      );
      expect(viewModel.message, '점수는 1~5 사이여야 합니다.');
      // 400은 목록을 다시 조회하지 않음
      expect(ratingServer.requests, hasLength(1));
    });

    test('404 on delete reloads the list before rethrowing', () async {
      serve((_) => (404, failure('COMMON404', '평점을 찾을 수 없습니다.')));

      await expectLater(
        viewModel.deleteRating(3),
        throwsA(isA<DioException>()),
      );
      expect(viewModel.message, contains('이미 삭제되었거나'));
      expect(ratingServer.requests.last.method, 'GET');
    });

    test('a saved write with a failed reload only warns', () async {
      serve((_) => (204, {}), getStatus: 500);
      await viewModel.deleteRating(3); // 던지지 않음

      expect(viewModel.status, MyRatingsStatus.error);
      expect(viewModel.refreshWarning, contains('저장은 완료됐지만'));
    });

    test('deleteSelectedRatings keeps only the failed ids selected', () async {
      serve(
        (options) => options.path.endsWith('/1')
            ? (500, failure('COMMON500', '서버 오류'))
            : (204, {}),
      );
      await viewModel.load();
      viewModel
        ..toggleSelected(3)
        ..toggleSelected(1);

      await viewModel.deleteSelectedRatings();

      expect(viewModel.isDeletingSelected, isFalse);
      expect(viewModel.selectedRatingIds, {1});
      expect(viewModel.message, '1개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.');
    });

    test(
      'a second delete of the same rating is ignored while in flight',
      () async {
        serve((_) => (204, {}));
        ratingServer.gate = Completer<void>();

        final first = viewModel.deleteRating(3);
        expect(viewModel.isDeleting(3), isTrue);
        await viewModel.deleteRating(3); // 바로 무시됨
        ratingServer.gate!.complete();
        await first;

        expect(
          ratingServer.requests.where((r) => r.method == 'DELETE'),
          hasLength(1),
        );
        expect(viewModel.isDeleting(3), isFalse);
      },
    );

    test('403 and 404 messages differ and both reload the list', () async {
      serve((_) => (403, failure('COMMON403', '권한 없음')));
      await expectLater(
        viewModel.deleteRating(3),
        throwsA(isA<DioException>()),
      );
      expect(viewModel.message, contains('내가 등록한 평점만'));
      expect(ratingServer.requests.last.method, 'GET');

      serve((_) => (404, {'error': 'no code'}));
      await expectLater(
        viewModel.deleteRating(3),
        throwsA(isA<DioException>()),
      );
      expect(viewModel.message, contains('이미 삭제되었거나'));
      expect(ratingServer.requests.last.method, 'GET');
    });
  });
}
