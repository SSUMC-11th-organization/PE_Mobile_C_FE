// 이번 세션 평점 저장소 테스트
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/session_ratings_store.dart';

import 'helpers/fake_movielog.dart';

RatingDto _rating(int ratingId, {int score = 4}) => RatingDto.fromJson(
  ratingResultJson(ratingId: ratingId, score: score)['result']!
      as Map<String, dynamic>,
);

void main() {
  late AuthViewModel auth;
  late SessionRatingsStore store;

  setUp(() async {
    auth = fakeAuthViewModel();
    await signIn(auth);
    store = SessionRatingsStore(auth);
  });

  test('add puts the newest rating first and replaces the same id', () {
    store
      ..add(_rating(1))
      ..add(_rating(2))
      ..add(_rating(1, score: 5));

    expect(store.ratings.map((r) => r.ratingId), [1, 2]);
    expect(store.ratings.first.score, 5);
  });

  test('replace updates only an existing rating', () {
    store.add(_rating(1));

    store
      ..replace(_rating(1, score: 2))
      ..replace(_rating(99));

    expect(store.ratings.single.score, 2);
  });

  test('remove deletes the rating', () {
    store
      ..add(_rating(1))
      ..add(_rating(2))
      ..remove(1);

    expect(store.ratings.map((r) => r.ratingId), [2]);
  });

  test('a new session (logout, expiry, login) clears the ratings', () async {
    store.add(_rating(1));
    await auth.logout();
    expect(store.ratings, isEmpty);

    store.add(_rating(2));
    await auth.login('movie@example.com', 'pw1234');
    expect(store.ratings, isEmpty);

    store.add(_rating(3));
    await auth.expireSession();
    expect(store.ratings, isEmpty);
  });

  test('loading the member in the same session keeps the ratings', () async {
    store.add(_rating(1));

    await auth.loadMember(force: true);

    expect(store.ratings, hasLength(1));
  });
}
