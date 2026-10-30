import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';

class FakeTmdbMovieService extends TmdbMovieService {
  FakeTmdbMovieService() : super(Dio());

  final requestedPages = <int>[];
  final requestedGenres = <int?>[];

  bool fail = false;
  bool returnEmpty = false;

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async {
    return const [
      TmdbGenreDto(id: 28, name: '액션'),
    ];
  }

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    int? genreId,
  }) async {
    requestedPages.add(page);
    requestedGenres.add(genreId);

    if (fail) {
      throw DioException(
        requestOptions: RequestOptions(
          path: '/discover/movie',
        ),
        type: DioExceptionType.connectionError,
      );
    }

    // 1페이지: ID 1~20
    // 2페이지: ID 16~35 → 앞 페이지와 일부 중복
    final firstId = page == 1 ? 1 : 16;

    final results = returnEmpty
        ? <TmdbMovieDto>[]
        : List.generate(
      20,
          (index) => TmdbMovieDto(
        id: firstId + index,
        title: '테스트 영화 ${firstId + index}',
        overview: '',
        posterPath: null,
        backdropPath: null,
        releaseDate: null,
        genreIds: [genreId ?? 28],
        voteAverage: 8.0,
        popularity: 1.0,
      ),
    );

    return TmdbMoviePageDto(
      page: page,
      results: results,
      totalPages: 2,
      totalResults: returnEmpty ? 0 : 40,
    );
  }
}

void main() {
  test('중복 ID를 제거하고 최대 30개를 구성한다', () async {
    final service = FakeTmdbMovieService();
    final viewModel = MovieListViewModel(service);
    addTearDown(viewModel.dispose);

    await viewModel.loadInitial();

    expect(viewModel.status, MovieListLoadStatus.success);
    expect(viewModel.movies.length, 30);

    final ids = viewModel.movies.map((movie) => movie.id).toSet();

    expect(ids.length, 30);
    expect(service.requestedPages, [1, 2]);
    expect(viewModel.genres.single.name, '액션');
  });

  test('장르 선택과 전체 선택 모두 1페이지부터 조회한다', () async {
    final service = FakeTmdbMovieService();
    final viewModel = MovieListViewModel(service);
    addTearDown(viewModel.dispose);

    await viewModel.loadInitial();

    service.requestedPages.clear();
    service.requestedGenres.clear();

    await viewModel.selectGenre(28);

    expect(viewModel.selectedGenreId, 28);
    expect(service.requestedPages, [1, 2]);
    expect(service.requestedGenres, [28, 28]);

    service.requestedPages.clear();
    service.requestedGenres.clear();

    await viewModel.selectGenre(null);

    expect(viewModel.selectedGenreId, isNull);
    expect(service.requestedPages, [1, 2]);
    expect(service.requestedGenres, [null, null]);
  });

  test('빈 응답이면 empty 상태가 된다', () async {
    final service = FakeTmdbMovieService()
      ..returnEmpty = true;

    final viewModel = MovieListViewModel(service);
    addTearDown(viewModel.dispose);

    await viewModel.loadInitial();

    expect(viewModel.status, MovieListLoadStatus.empty);
    expect(viewModel.movies, isEmpty);
    expect(service.requestedPages, [1]);
  });

  test('조회 실패 후 재시도하면 성공 상태로 복구한다', () async {
    final service = FakeTmdbMovieService()
      ..fail = true;

    final viewModel = MovieListViewModel(service);
    addTearDown(viewModel.dispose);

    final statuses = <MovieListLoadStatus>[];

    viewModel.addListener(() {
      statuses.add(viewModel.status);
    });

    await viewModel.loadInitial();

    expect(viewModel.status, MovieListLoadStatus.error);
    expect(viewModel.message, isNotEmpty);

    service.fail = false;

    await viewModel.loadInitial();

    expect(viewModel.status, MovieListLoadStatus.success);
    expect(viewModel.message, isNull);
    expect(
      statuses,
      [
        MovieListLoadStatus.loading,
        MovieListLoadStatus.error,
        MovieListLoadStatus.loading,
        MovieListLoadStatus.success,
      ],
    );
  });
}