import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/token_storage.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/session_ratings_store.dart';

class FakeTokenStorage implements TokenStorage {
  @override
  Future<void> deleteAccessToken() async {}

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<void> saveAccessToken(String token) async {}
}

class FakeRatingService extends RatingApiService {
  FakeRatingService() : super(Dio());

  final deleted = <int>[];
  final failedIds = <int>{};
  Completer<void>? gate;

  @override
  Future<void> deleteRating(int ratingId) async {
    deleted.add(ratingId);
    await gate?.future;
    if (failedIds.contains(ratingId)) {
      throw DioException(
        requestOptions: RequestOptions(path: '/v8/ratings/$ratingId'),
      );
    }
  }
}

RatingDto _rating(int id) => RatingDto(
  ratingId: id,
  movieId: id + 100,
  score: 4,
  comment: null,
  createdAt: DateTime(2026, 11, 21),
);

void main() {
  test('삭제 중 중복 실행을 막고 실패한 항목만 선택을 유지한다', () async {
    final service = FakeRatingService()
      ..failedIds.add(2)
      ..gate = Completer<void>();
    final auth = _signedInAuth();
    final store = SessionRatingsStore(auth)
      ..add(_rating(1))
      ..add(_rating(2));
    final model = MyRatingsViewModel(
      service,
      TmdbMovieService(Dio()),
      store,
      auth,
    );
    addTearDown(model.dispose);
    addTearDown(store.dispose);
    addTearDown(auth.dispose);
    model.toggleRatingSelection(1);
    model.toggleRatingSelection(2);
    final pending = model.deleteSelectedRatings();
    expect(model.isDeletingSelected, isTrue);
    await model.deleteSelectedRatings();
    expect(service.deleted, [1]);
    service.gate!.complete();
    await pending;
    expect(service.deleted, [1, 2]);
    expect(model.selectedRatingIds, {2});
    expect(model.isDeletingSelected, isFalse);
    expect(model.message, contains('1개'));
  });

  test('삭제한 평점은 세션 목록을 다시 읽어도 나타나지 않는다', () async {
    final service = FakeRatingService();
    final auth = _signedInAuth();
    final store = SessionRatingsStore(auth)..add(_rating(1));
    final model = MyRatingsViewModel(
      service,
      TmdbMovieService(Dio()),
      store,
      auth,
    );
    addTearDown(model.dispose);
    addTearDown(store.dispose);
    addTearDown(auth.dispose);
    model.toggleRatingSelection(1);
    await model.deleteSelectedRatings();
    expect(model.isDeletingSelected, isFalse);
    expect(model.selectedRatingIds, isEmpty);
    expect(model.status, MyRatingsLoadStatus.empty);
    await model.load();
    expect(model.ratings, isEmpty);
    expect(service.deleted, [1]);
  });
}

AuthViewModel _signedInAuth() => AuthViewModel(
  AuthApiService(Dio()),
  MemberApiService(Dio()),
  FakeTokenStorage(),
)..status = AuthStatus.signedIn;
