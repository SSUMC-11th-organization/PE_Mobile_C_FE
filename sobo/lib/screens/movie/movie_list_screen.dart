import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_movies.dart';
import '../../services/movie/fake_movie_service.dart';
import '../../services/storage/genre_preference.dart';
import '../../widgets/common/common_app_bar.dart';
import '../../widgets/movie/cards/movie_grid.dart';
import '../../widgets/movie/states/movie_list_empty.dart';
import '../../widgets/movie/states/movie_list_error.dart';
import '../../widgets/movie/states/movie_list_loading.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, required this.selectedGenres});

  final List<String> selectedGenres;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final movieService = const FakeMovieService();
  final genrePreference = GenrePreference();

  late Future<List<Movie>> _moviesFuture;

  @override
  void initState() {
    super.initState();

    // 최초 영화 조회
    _moviesFuture = movieService.fetchMovies();
    _restoreGenres(); // 앱 재실행 시 복원
  }

  // 새 Future를 만들어 다시 조회
  void _retry() {
    setState(() {
      _moviesFuture = movieService.fetchMovies();
    });
  }

  // RefreshIndicator가 조회 완료까지 새로고침 표시를 유지하도록 기다린다.
  Future<void> _refresh() async {
    final refreshedMovies = movieService.fetchMovies();

    setState(() {
      _moviesFuture = refreshedMovies;
    });

    try {
      await refreshedMovies;
    } catch (error) {
      // 오류 화면은 기존 FutureBuilder의 hasError 분기에서 표시한다.
      debugPrint('영화 새로고침 실패: $error');
    }
  }

  // 영화가 없는 상태에서도 아래로 당길 수 있는 세로 스크롤 영역.
  Widget _refreshableStatus(Widget child) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
    );
  }

  Future<void> _changeGenres(List<String> selectedGenres) async {
    try {
      await genrePreference.save(selectedGenres);

      if (!mounted) return;

      final uri = Uri(
        path: '/movies',
        queryParameters: selectedGenres.isEmpty
            ? null
            : {'genre': selectedGenres},
      );

      context.go(uri.toString());
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장르를 저장하지 못했어요. 다시 선택해 주세요.')),
      );
    }
  }

  Future<void> _restoreGenres() async {
    // 주소에 장르 조건이 있으면 그 선택을 우선 사용
    if (widget.selectedGenres.isNotEmpty) return;

    try {
      final savedGenres = await genrePreference.read();

      if (!mounted) return;

      // 빈 목록은 전체 선택이므로 주소를 바꿀 필요 없음
      if (savedGenres.isEmpty) return;

      final uri = Uri(path: '/movies', queryParameters: {'genre': savedGenres});

      context.go(uri.toString());
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('저장된 장르를 불러오지 못했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final genres = movies.map((movie) => movie.genre).toSet().toList();

    return Scaffold(
      appBar: CommonAppBar(title: '영화'),
      body: Column(
        children: [
          // 장르 Chip 가로 목록
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('전체'),
                    selected: widget.selectedGenres.isEmpty,
                    onSelected: (_) {
                      _changeGenres([]);
                    },
                  ),
                ),
                for (final genre in genres)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(genre),
                      selected: widget.selectedGenres.contains(genre),
                      onSelected: (selected) {
                        // 원본 대신 복사한 목록을 수정
                        final nextGenres = List<String>.of(
                          widget.selectedGenres,
                        );

                        if (selected) {
                          nextGenres.add(genre);
                        } else {
                          nextGenres.remove(genre);
                        }

                        _changeGenres(nextGenres);
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Chip 아래의 남은 공간에 영화 화면 표시
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Movie>>(
                future: _moviesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const MovieListLoading();
                  }

                  if (snapshot.hasError) {
                    return _refreshableStatus(MovieListError(onRetry: _retry));
                  }

                  final loadedMovies = snapshot.data ?? const <Movie>[];

                  final filteredMovies = widget.selectedGenres.isEmpty
                      ? loadedMovies
                      : loadedMovies
                            .where(
                              (movie) =>
                                  widget.selectedGenres.contains(movie.genre),
                            )
                            .toList();

                  if (filteredMovies.isEmpty) {
                    return _refreshableStatus(const MovieListEmpty());
                  }

                  return MovieGrid(movies: filteredMovies);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
