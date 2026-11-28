import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';

class FakeTmdbMovieService extends TmdbMovieService {
  FakeTmdbMovieService() : super(Dio());

  final requestedPages = <int>[];
  final requestedGenres = <int?>[];

  bool fail = false;
  bool returnEmpty = false;

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    int? genreId,
  }) async {
    requestedPages.add(page);
    requestedGenres.add(genreId);

    if (fail) {
      throw DioException(
        requestOptions: RequestOptions(path: '/discover/movie'),
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
  test('첫 페이지만 조회하고 더 보기에서 중복 없이 영화를 추가한다', () async {
    final service = FakeTmdbMovieService();
    final viewModel = PagedMoviesViewModel(tmdbApi: service);
    addTearDown(viewModel.dispose);

    await viewModel.loadInitial();

    expect(viewModel.phase, LoadPhase.ready);
    expect(viewModel.movies.length, 20);
    expect(service.requestedPages, [1]);

    await viewModel.loadNextPage();

    final ids = viewModel.movies.map((movie) => movie.id).toSet();

    expect(viewModel.movies.length, 35);
    expect(ids.length, 35);
    expect(service.requestedPages, [1, 2]);
    expect(viewModel.hasMore, isFalse);
  });

  test('장르 선택과 전체 선택 모두 1페이지부터 조회한다', () async {
    final service = FakeTmdbMovieService();
    final viewModel = PagedMoviesViewModel(tmdbApi: service);
    addTearDown(viewModel.dispose);

    await viewModel.loadInitial();

    service.requestedPages.clear();
    service.requestedGenres.clear();

    await viewModel.loadInitial(genreId: 28);

    expect(service.requestedPages, [1]);
    expect(service.requestedGenres, [28]);

    service.requestedPages.clear();
    service.requestedGenres.clear();

    await viewModel.loadInitial();

    expect(service.requestedPages, [1]);
    expect(service.requestedGenres, [null]);
  });

  test('빈 응답이면 empty 상태가 된다', () async {
    final service = FakeTmdbMovieService()..returnEmpty = true;

    final viewModel = PagedMoviesViewModel(tmdbApi: service);
    addTearDown(viewModel.dispose);

    await viewModel.loadInitial();

    expect(viewModel.phase, LoadPhase.empty);
    expect(viewModel.movies, isEmpty);
    expect(service.requestedPages, [1]);
  });

  test('조회 실패 후 재시도하면 성공 상태로 복구한다', () async {
    final service = FakeTmdbMovieService()..fail = true;

    final viewModel = PagedMoviesViewModel(tmdbApi: service);
    addTearDown(viewModel.dispose);

    final statuses = <LoadPhase>[];

    viewModel.addListener(() {
      statuses.add(viewModel.phase);
    });

    await viewModel.loadInitial();

    expect(viewModel.phase, LoadPhase.error);
    expect(viewModel.errorMessage, isNotEmpty);

    service.fail = false;

    await viewModel.loadInitial();

    expect(viewModel.phase, LoadPhase.ready);
    expect(viewModel.errorMessage, isNull);
    expect(statuses, [
      LoadPhase.loading,
      LoadPhase.error,
      LoadPhase.loading,
      LoadPhase.ready,
    ]);
  });
}
