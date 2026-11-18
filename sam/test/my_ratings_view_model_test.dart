// 내가 등록한 평점 ViewModel 테스트 (이번 세션 평점 + 토큰 기반 수정·삭제)
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/session_ratings_store.dart';

import 'helpers/fake_movielog.dart';

Map<String, Object> _failure(String code, String message) => {
  'isSuccess': false,
  'code': code,
  'message': message,
};

RatingDto _rating({required int ratingId, int movieId = 13, int score = 4}) =>
    RatingDto.fromJson(
      ratingResultJson(
            ratingId: ratingId,
            movieId: movieId,
            score: score,
          )['result']!
          as Map<String, dynamic>,
    );

void main() {
  late FakeMovieLogAdapter ratingServer;
  late FakeMovieLogAdapter tmdbServer;
  late AuthViewModel auth;
  late SessionRatingsStore store;
  late MyRatingsViewModel viewModel;

  setUp(() async {
    ratingServer = FakeMovieLogAdapter((_) => (200, {}));
    tmdbServer = FakeMovieLogAdapter((options) {
      final id = int.parse(options.path.split('/').last);
      return (200, movieDetailJson(id));
    });
    auth = fakeAuthViewModel();
    await signIn(auth);
    // ratingId 3(movieId 13, 3점), ratingId 1(movieId 550, 5점)
    store = seededRatingsStore(auth);
    viewModel = MyRatingsViewModel(
      fakeRatingService(ratingServer),
      TmdbMovieService(fakeDio(tmdbServer)),
      store,
      auth,
    );
  });

  List<RequestOptions> requestsOf(String method) =>
      ratingServer.requests.where((r) => r.method == method).toList();

  test('starts idle', () {
    expect(viewModel.status, MyRatingsStatus.idle);
  });

  group('목록', () {
    test('shows the session ratings without a list GET', () async {
      await viewModel.load();

      expect(viewModel.status, MyRatingsStatus.success);
      expect(viewModel.ratings.map((r) => r.ratingId), [3, 1]);
      expect(viewModel.moviesById.keys, unorderedEquals([13, 550]));
      expect(ratingServer.requests, isEmpty);
    });

    test('an empty session becomes empty', () async {
      viewModel = MyRatingsViewModel(
        fakeRatingService(ratingServer),
        TmdbMovieService(fakeDio(tmdbServer)),
        SessionRatingsStore(auth),
        auth,
      );

      await viewModel.load();

      expect(viewModel.status, MyRatingsStatus.empty);
    });

    test('a failed movie lookup keeps the rating list', () async {
      tmdbServer.route = (options) => options.path.endsWith('/13')
          ? (404, {'status_message': 'not found'})
          : (200, movieDetailJson(550));

      await viewModel.load();

      expect(viewModel.ratings, hasLength(2));
      expect(viewModel.moviesById.containsKey(13), isFalse);
      expect(viewModel.moviesById.containsKey(550), isTrue);
    });

    test('reloading does not refetch cached movies', () async {
      await viewModel.load();
      final firstCount = tmdbServer.requests.length;

      await viewModel.load();

      expect(tmdbServer.requests.length, firstCount);
    });

    test('a rating added to the store shows up', () async {
      await viewModel.load();

      store.add(_rating(ratingId: 9, movieId: 77));

      expect(viewModel.ratings.first.ratingId, 9);
    });
  });

  group('수정·삭제', () {
    setUp(() async => viewModel.load());

    test('updateRating replaces the card with the PATCH result', () async {
      ratingServer.route = (_) => (
        200,
        ratingResultJson(ratingId: 3, movieId: 13, score: 4, comment: '좋아요'),
      );

      await viewModel.updateRating(ratingId: 3, score: 4, comment: '좋아요');

      final patch = requestsOf('PATCH').single;
      expect(patch.path, '/v7/ratings/3');
      expect(patch.data, {'score': 4, 'comment': '좋아요'});
      final card = viewModel.ratings.firstWhere((r) => r.ratingId == 3);
      expect(card.score, 4);
      expect(card.comment, '좋아요');
      // 목록을 서버에서 다시 받지 않음
      expect(requestsOf('GET'), isEmpty);
    });

    test('a failed write rethrows with the server message', () async {
      ratingServer.route = (_) => (400, _failure('COMMON400', '점수를 확인해 주세요.'));

      await expectLater(
        viewModel.updateRating(ratingId: 3, score: 4),
        throwsA(isA<DioException>()),
      );

      expect(viewModel.message, '점수를 확인해 주세요.');
      expect(viewModel.ratings.firstWhere((r) => r.ratingId == 3).score, 3);
    });

    test('deleteRating removes the card after 200', () async {
      await viewModel.deleteRating(3);

      expect(requestsOf('DELETE').single.path, '/v7/ratings/3');
      expect(viewModel.ratings.map((r) => r.ratingId), [1]);
      expect(store.ratings.map((r) => r.ratingId), [1]);
    });

    test('404 on delete removes the card and rethrows', () async {
      ratingServer.route = (_) => (404, _failure('COMMON404', '없음'));

      await expectLater(
        viewModel.deleteRating(3),
        throwsA(isA<DioException>()),
      );

      expect(viewModel.message, contains('이미 삭제되었거나'));
      expect(viewModel.ratings.map((r) => r.ratingId), [1]);
    });

    test('403 keeps the card and the session', () async {
      ratingServer.route = (_) => (403, _failure('COMMON403', '권한 없음'));

      await expectLater(
        viewModel.deleteRating(3),
        throwsA(isA<DioException>()),
      );

      expect(viewModel.message, contains('내가 등록한 평점만'));
      expect(viewModel.ratings, hasLength(2));
      expect(auth.status, AuthStatus.signedIn);
    });

    test('deleteSelectedRatings keeps only the failed ids selected', () async {
      ratingServer.route = (options) => options.path.endsWith('/1')
          ? (500, _failure('COMMON500', '오류'))
          : (200, {});
      viewModel
        ..toggleSelected(3)
        ..toggleSelected(1);

      await viewModel.deleteSelectedRatings();

      expect(viewModel.selectedRatingIds, {1});
      expect(viewModel.ratings.map((r) => r.ratingId), [1]);
      expect(viewModel.message, contains('1개 항목을 삭제하지 못했습니다'));
    });

    test(
      'a second delete of the same rating is ignored while in flight',
      () async {
        ratingServer.gate = Completer<void>();

        final first = viewModel.deleteRating(3);
        expect(viewModel.isDeleting(3), isTrue);
        await viewModel.deleteRating(3); // 바로 무시됨
        ratingServer.gate!.complete();
        await first;

        expect(requestsOf('DELETE'), hasLength(1));
        expect(viewModel.isDeleting(3), isFalse);
      },
    );
  });

  group('로그인 세션', () {
    setUp(() async => viewModel.load());

    for (final code in ['AUTH401_2', 'AUTH401_3', 'AUTH401_4']) {
      test('$code on update expires the session', () async {
        ratingServer.route = (_) => (401, _failure(code, '만료'));

        await expectLater(
          viewModel.updateRating(ratingId: 3, score: 4),
          throwsA(isA<DioException>()),
        );

        expect(auth.status, AuthStatus.signedOut);
        expect(auth.sessionExpired, isTrue);
        // 세션이 바뀌어 이번 세션의 평점도 비워짐
        expect(viewModel.ratings, isEmpty);
      });
    }

    test('logging out clears the session ratings', () async {
      await auth.logout();

      expect(store.ratings, isEmpty);
      expect(viewModel.status, MyRatingsStatus.empty);
    });

    test('a PATCH that finishes after logout is not applied', () async {
      ratingServer.gate = Completer<void>();
      ratingServer.route = (_) =>
          (200, ratingResultJson(ratingId: 3, movieId: 13, score: 1));

      final updating = viewModel.updateRating(ratingId: 3, score: 1);
      await auth.logout();
      // 다시 로그인해 새 세션에서 같은 영화의 평점을 등록한 상황
      await signIn(auth);
      store.add(_rating(ratingId: 3, score: 5));
      ratingServer.gate!.complete();
      await updating;

      // 이전 세션의 늦은 응답(1점)이 새 세션의 평점(5점)을 덮어쓰지 않음
      expect(store.ratings.single.score, 5);
    });
  });
}
