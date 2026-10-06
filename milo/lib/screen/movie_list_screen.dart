import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/genre_preference.dart';
import 'package:movielog/data/mock_movie.dart';
import 'package:movielog/data/movie_sort_option.dart';
import 'package:movielog/data/sort_preference.dart';
import 'package:movielog/service/fake_movie_service.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/widgets/movie/genre_filter_sheet.dart';
import 'package:movielog/widgets/movie/movie_grid.dart';
import 'package:movielog/widgets/movie/movie_list_empty.dart';
import 'package:movielog/widgets/movie/movie_list_error.dart';
import 'package:movielog/widgets/movie/movie_list_loading.dart';
import 'package:movielog/widgets/movie/sort_option_sheet.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, this.initialGenres = const []});

  final List<String> initialGenres;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const allGenres = ['드라마', 'SF', '애니메이션', '스릴러', '로맨스', '액션', '다큐멘터리'];

  late Set<String> appliedGenres = widget.initialGenres.toSet();

  final movieService = const FakeMovieService();
  late Future<List<Movie>> _moviesFuture;

  final genrePreference = GenrePreference();
  final sortPreference = SortPreference();

  MovieSortOption sortOption = MovieSortOption.none;

  @override
  void initState() {
    super.initState();
    // _restoreGenres();
    _restorePreferences();
    _moviesFuture = movieService.fetchMovies();
    // _moviesFuture = movieService.fetchMovies(mode: MovieLoadMode.timeout);
    // _moviesFuture = movieService.fetchMovies(
    //   mode: MovieLoadMode.failure,
    // ); // 테스트용
  }

  List<Movie> _sorted(List<Movie> list) {
    final copy = list.toList();
    switch (sortOption) {
      case MovieSortOption.none:
        // 정렬 안 함
        break;
      case MovieSortOption.ratingDesc:
        copy.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case MovieSortOption.titleAsc:
        copy.sort((a, b) => a.title.compareTo(b.title));
        break;
      case MovieSortOption.yearDesc:
        copy.sort((a, b) => b.year.compareTo(a.year));
        break;
    }
    return copy;
  }

  // List<Movie> get filteredMovies {
  //   if (appliedGenres.isEmpty) return movies;
  //   return movies
  //       .where((movie) => appliedGenres.contains(movie.genre))
  //       .toList();
  // }

  // Future<void> _restoreGenres() async {
  //   if (widget.initialGenres.isEmpty) {
  //     final saved = (await genrePreference.read()).toSet();
  //     if (!mounted) return;

  //     setState(() {
  //       appliedGenres = saved;
  //     });
  //   }
  // }

  Future<void> _restorePreferences() async {
    // 정렬은 URL과 무관하므로 항상 복원한다.
    final savedSort = await sortPreference.read();

    // 장르는 URL에 genre 쿼리가 없을 때만 복원한다.
    final savedGenres = widget.initialGenres.isEmpty
        ? (await genrePreference.read()).toSet()
        : null;

    if (!mounted) return;
    setState(() {
      sortOption = savedSort;
      if (savedGenres != null) appliedGenres = savedGenres;
    });
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => GenreFilterSheet(
        allGenres: allGenres,
        initialSelected: appliedGenres,
      ),
    );

    if (result == null) return;
    if (!mounted) return;

    genrePreference.save(result.toList());

    setState(() => appliedGenres = result);

    final location = result.isEmpty
        ? '/movies'
        : Uri(
            path: '/movies',
            queryParameters: {'genre': result.join(',')},
          ).toString();

    context.go(location);
  }

  Future<void> _openSortSheet() async {
    final result = await showModalBottomSheet<MovieSortOption>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => SortOptionSheet(selected: sortOption),
    );

    if (result == null) return;
    if (!mounted) return;
    setState(() => sortOption = result);
    sortPreference.save(result);
  }

  void _retry() {
    setState(() {
      _moviesFuture = movieService.fetchMovies();
    });
  }

  Future<void> _refresh() async {
    Future<List<Movie>> movies = movieService.fetchMovies();
    setState(() {
      _moviesFuture = movies;
    });
    try {
      await movies;
    } on Exception catch (_) {
      //Error 화면은 FutureBuilder가 표시
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          '영화',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6750A4),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: AppColors.onSurfaceVariant),
          ),
          IconButton(
            onPressed: _openFilterSheet,
            icon: Icon(
              Icons.filter_list,
              color: appliedGenres.isEmpty
                  ? AppColors.onSurfaceVariant
                  : AppColors.primary,
            ),
          ),
          IconButton(
            onPressed: _openSortSheet,
            icon: Icon(
              Icons.sort,
              color: sortOption == MovieSortOption.none
                  ? AppColors.onSurfaceVariant
                  : AppColors.primary,
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Movie>>(
        future: _moviesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const MovieListLoading();
          }

          if (snapshot.hasError) {
            final String message = (snapshot.error is TimeoutException)
                ? '응답이 너무 오래 걸립니다. 잠시 후 다시 시도해주세요.'
                : '영화를 불러오지 못했습니다.';
            return MovieListError(onRetry: _retry, message: message);
          }

          final movies = snapshot.data ?? const <Movie>[];
          final List<Movie> filteredMovies;
          if (appliedGenres.isEmpty) {
            filteredMovies = movies.toList();
          } else {
            filteredMovies = movies
                .where((movie) => appliedGenres.contains(movie.genre))
                .toList();
          }

          if (filteredMovies.isEmpty) {
            return const MovieListEmpty();
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: MovieGrid(movies: _sorted(filteredMovies)),
          );
        },
      ),
    );
  }
}
