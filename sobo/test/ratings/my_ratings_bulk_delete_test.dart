import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/services/rating_api_service.dart';
import 'package:movielog/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';

class FakeRatingService extends RatingApiService {
  FakeRatingService() : super(Dio());
  final deleted = <int>[];
  final failedIds = <int>{};
  Completer<void>? gate;
  bool failGet = false;
  int gets = 0;

  @override
  Future<void> deleteRating({required int memberId, required int ratingId}) async {
    deleted.add(ratingId);
    await gate?.future;
    if (failedIds.contains(ratingId)) {
      throw DioException(requestOptions: RequestOptions(path: '/ratings/$ratingId'));
    }
  }

  @override
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    gets++;
    if (failGet) {
      throw DioException(requestOptions: RequestOptions(path: '/ratings'));
    }
    return [];
  }
}

void main() {
  test('삭제 중 중복 실행을 막고 실패한 항목만 선택을 유지한다', () async {
    final service = FakeRatingService()
      ..failedIds.add(2)
      ..gate = Completer<void>();
    final model = MyRatingsViewModel(service, TmdbMovieService(Dio()), 7);
    addTearDown(model.dispose);
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
    expect(service.gets, 1);
    expect(model.message, contains('1개'));
  });

  test('삭제 성공 후 조회 실패는 삭제를 반복하지 않고 조회만 재시도한다', () async {
    final service = FakeRatingService()..failGet = true;
    final model = MyRatingsViewModel(service, TmdbMovieService(Dio()), 7);
    addTearDown(model.dispose);
    model.toggleRatingSelection(1);
    await model.deleteSelectedRatings();
    expect(model.isDeletingSelected, isFalse);
    expect(model.selectedRatingIds, isEmpty);
    expect(model.refreshWarning, isNotNull);
    service.failGet = false;
    await model.load();
    expect(service.deleted, [1]);
    expect(service.gets, 2);
    expect(model.refreshWarning, isNull);
  });
}
