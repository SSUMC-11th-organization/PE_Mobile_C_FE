import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../models/movie_list_initial_data.dart';
import '../models/movie_sort.dart';
import '../services/genre_preference.dart';
import '../services/movie_service.dart';
import '../services/sort_preference.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/movie_widget/genre_chip_bar.dart';
import '../widgets/movie_widget/movie_grid.dart';
import '../widgets/movie_widget/movie_list_empty.dart';
import '../widgets/movie_widget/movie_list_error.dart';
import '../widgets/movie_widget/movie_list_loading.dart';
import '../widgets/movie_widget/movie_sort_button.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({
    super.key,
    this.movieService = const FakeMovieService(),
    this.genrePreference,
    this.sortPreference,
    this.timeout = const Duration(seconds: 3),
  });

  final FakeMovieService movieService;
  final GenrePreference? genrePreference;
  final SortPreference? sortPreference;
  final Duration timeout;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static final _genres = [GenrePreference.allGenres, ...mockGenres];

  late final GenrePreference _genrePreference =
      widget.genrePreference ?? GenrePreference();
  late final SortPreference _sortPreference =
      widget.sortPreference ?? SortPreference();

  late Future<MovieListInitialData> _initialDataFuture;
  MovieListInitialData? _lastData;
  MovieLoadMode _mode = MovieLoadMode.success;
  String? _selectedGenre;
  MovieSort? _selectedSort;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _initialDataFuture = _loadInitialData();
  }

  Future<MovieListInitialData> _loadInitialData() async {
    try {
      final results = await Future.wait([
        widget.movieService.fetchMovies(mode: _mode).timeout(widget.timeout),
        _genrePreference.read(),
        _sortPreference.read(),
      ]);

      final data = MovieListInitialData(
        movies: results[0] as List<Movie>,
        selectedGenre: results[1] as String,
        selectedSort: results[2] as MovieSort,
      );
      _lastData = data;
      return data;
    } on MovieLoadException catch (error, stackTrace) {
      debugPrint('영화 로드 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('영화 로드 시간 초과: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } finally {
      debugPrint('영화 로드 시도 종료');
    }
  }

  void _changeMode(MovieLoadMode mode) {
    setState(() {
      _mode = mode;
      _initialDataFuture = _loadInitialData();
    });
  }

  void _retry() {
    setState(() {
      _mode = MovieLoadMode.success;
      _initialDataFuture = _loadInitialData();
    });
  }

  Future<void> _refresh() async {
    final future = _loadInitialData();
    setState(() {
      _refreshing = true;
      _initialDataFuture = future;
    });

    try {
      await future;
    } catch (_) {
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _selectGenre(String genre) async {
    setState(() => _selectedGenre = genre);
    try {
      await _genrePreference.save(genre);
    } catch (error) {
      debugPrint('장르 저장 실패: $error');
    }
  }

  Future<void> _selectSort(MovieSort sort) async {
    setState(() => _selectedSort = sort);
    try {
      await _sortPreference.save(sort);
    } catch (error) {
      debugPrint('정렬 저장 실패: $error');
    }
  }

  List<Movie> _filter(List<Movie> movies, String genre) {
    if (genre == GenrePreference.allGenres) return movies;
    return movies.where((movie) => movie.genres.contains(genre)).toList();
  }

  Widget _refreshable(Widget child) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: child,
    );
  }

  Widget _scrollableCenter(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [SizedBox(height: constraints.maxHeight, child: child)],
      ),
    );
  }

  Widget _buildBody(AsyncSnapshot<MovieListInitialData> snapshot) {
    final waiting = snapshot.connectionState == ConnectionState.waiting;

    if (waiting && !(_refreshing && _lastData != null)) {
      return const MovieListLoading();
    }

    if (!waiting && snapshot.hasError) {
      if (snapshot.error is TimeoutException) {
        return MovieListError(
          onRetry: _retry,
          title: '응답이 너무 오래 걸리고 있어요.',
          description: '네트워크 상태를 확인하고 다시 시도해 주세요.',
        );
      }
      return MovieListError(onRetry: _retry);
    }

    final data = (waiting ? _lastData : snapshot.data)!;
    final saved = _genres.contains(data.selectedGenre)
        ? data.selectedGenre
        : GenrePreference.allGenres;
    final selectedGenre = _selectedGenre ?? saved;
    final selectedSort = _selectedSort ?? data.selectedSort;
    final movies = selectedSort.apply(_filter(data.movies, selectedGenre));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GenreChipBar(
                genres: _genres,
                selectedGenre: selectedGenre,
                onSelected: _selectGenre,
              ),
            ),
            MovieSortButton(
              selectedSort: selectedSort,
              onSelected: _selectSort,
            ),
          ],
        ),
        Expanded(
          child: _refreshable(
            movies.isEmpty
                ? _scrollableCenter(const MovieListEmpty())
                : MovieGrid(movies: movies),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '영화',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<MovieLoadMode>(
            icon: const Icon(Icons.science_outlined, color: AppColors.primary),
            tooltip: '로드 상태 테스트',
            initialValue: _mode,
            onSelected: _changeMode,
            itemBuilder: (context) => const [
              PopupMenuItem(value: MovieLoadMode.success, child: Text('성공')),
              PopupMenuItem(value: MovieLoadMode.empty, child: Text('빈 목록')),
              PopupMenuItem(value: MovieLoadMode.failure, child: Text('실패')),
              PopupMenuItem(value: MovieLoadMode.timeout, child: Text('응답 지연')),
            ],
          ),
          IconButton(
            onPressed: () => debugPrint('검색 버튼을 눌렀습니다.'),
            icon: const Icon(Icons.search, color: AppColors.primary),
          ),
        ],
      ),
      body: FutureBuilder<MovieListInitialData>(
        future: _initialDataFuture,
        builder: (context, snapshot) => _buildBody(snapshot),
      ),
    );
  }
}
