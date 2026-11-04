// 내가 등록한 평점 ViewModel 테스트
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
      sampleMemberId,
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
}
