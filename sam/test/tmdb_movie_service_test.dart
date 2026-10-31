// TMDB 서비스·DTO·로그 마스킹 테스트
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/models/tmdb_movie_dto.dart';
import 'package:dio/dio.dart';
import 'package:movielog/services/tmdb_dio.dart';
import 'package:movielog/services/tmdb_logging_interceptor.dart';
import 'package:movielog/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

import 'helpers/fake_tmdb.dart';

void main() {
  group('fetchUpToThirtyMovies', fetchUpToThirtyMoviesTests);

  test('fetchPopular requests /movie/popular and parses the page', () async {
    final adapter = FakeTmdbAdapter(body: moviePageJson(3));

    final page = await fakeTmdbService(adapter).fetchPopular();

    expect(adapter.requests.single.path, '/movie/popular');
    expect(adapter.requests.single.queryParameters['language'], 'ko-KR');
    expect(page.results, hasLength(3));
    expect(page.results.first.title, '인기 영화 1');
  });

  test('a 401 response is shown as a token error message', () async {
    final adapter = FakeTmdbAdapter(
      statusCode: 401,
      body: {'status_message': 'Invalid API key'},
    );

    final error = await fakeTmdbService(adapter)
        .fetchPopular()
        .then<Object?>((_) => null, onError: (Object e) => e);

    expect(error, isA<DioException>());
    expect(tmdbErrorMessage(error!), contains('토큰'));
  });

  test('discoverMovies sends with_genres only when a genre is given', () async {
    final adapter = FakeTmdbAdapter(body: discoverPageJson([1]));
    final service = fakeTmdbService(adapter);

    await service.discoverMovies(page: 1);
    await service.discoverMovies(page: 1, genreId: 28);

    expect(
      adapter.requests.first.queryParameters.containsKey('with_genres'),
      isFalse,
    );
    expect(adapter.requests.last.queryParameters['with_genres'], 28);
  });

  test('toMovie maps poster, genre and year', () {
    final movie = TmdbMovieDto.fromJson({
      'id': 1,
      'title': '테스트',
      'genre_ids': [878, 28],
      'poster_path': '/abc.jpg',
      'release_date': '2024-05-01',
    }).toMovie();

    expect(movie.posterUrl, 'https://image.tmdb.org/t/p/w500/abc.jpg');
    expect(movie.genre, 'SF');
    expect(movie.year, 2024);
  });

  test('toMovie handles a missing poster, genre and release date', () {
    final movie = TmdbMovieDto.fromJson({
      'id': 1,
      'title': '테스트',
      'genre_ids': <int>[],
      'poster_path': null,
      'release_date': '',
    }).toMovie();

    expect(movie.posterUrl, isNull);
    expect(movie.genre, '기타');
    expect(movie.year, isNull);
  });

  test('logging interceptor never prints the access token', () async {
    final logs = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');
    addTearDown(() => debugPrint = originalDebugPrint);

    const token = 'eyJhbGciOiJIUzI1NiJ9.secret-part.abcd';
    final dio =
        Dio(
            BaseOptions(
              baseUrl: 'https://api.themoviedb.org/3',
              headers: {'Authorization': 'Bearer $token'},
            ),
          )
          ..httpClientAdapter = FakeTmdbAdapter(body: moviePageJson(1))
          ..interceptors.add(TmdbLoggingInterceptor());

    await TmdbMovieService(dio).fetchPopular();

    expect(logs.any((log) => log.contains('Bearer ***')), isTrue);
    expect(logs.any((log) => log.contains('secret-part')), isFalse);
    expect(logs.any((log) => log.startsWith('[TMDB 응답] 200')), isTrue);
  });
}

void fetchUpToThirtyMoviesTests() {
  test('collects 30 unique movies across pages and stops requesting', () async {
    // 페이지마다 20개, 2페이지 앞 5개는 1페이지와 중복
    final adapter = FakeTmdbAdapter(
      responder: (options) {
        final page = options.queryParameters['page'] as int;
        final start = page == 1 ? 1 : 16 + (page - 2) * 20;
        return (
          200,
          discoverPageJson(
            [for (var i = start; i < start + 20; i++) i],
            page: page,
            totalPages: 10,
          ),
        );
      },
    );

    final movies = await MovieListViewModel(fakeTmdbService(adapter))
        .fetchUpToThirtyMovies();

    expect(movies, hasLength(30));
    expect(movies.map((movie) => movie.id).toSet(), hasLength(30));
    expect(adapter.requests, hasLength(2));
  });

  test('returns what exists when there are fewer than 30 movies', () async {
    final adapter = FakeTmdbAdapter(body: discoverPageJson([1, 2, 3]));

    final movies = await MovieListViewModel(fakeTmdbService(adapter))
        .fetchUpToThirtyMovies(genreId: 18);

    expect(movies, hasLength(3));
    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.queryParameters['with_genres'], 18);
  });
}
