// 영화 목록 화면 구현
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/movie.dart';
import '../services/fake_movie_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_grid.dart';

const _allGenres = '전체';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({
    super.key,
    this.service = const FakeMovieService(),
    this.mode = MovieLoadMode.success,
  });

  final FakeMovieService service;
  final MovieLoadMode mode;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  String _selectedGenre = _allGenres;
  late Future<List<Movie>> _moviesFuture;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  void _loadMovies() {
    _moviesFuture = widget.service.fetchMovies(mode: widget.mode);
  }

  @override
  Widget build(BuildContext context) {
    final margin = AppSpacing.screenMargin(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: '영화',
        actions: [
          IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(
              'assets/icons/search.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.black,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Movie>>(
        future: _moviesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            return _MessageView(
              message: error is MovieLoadException
                  ? error.message
                  : '알 수 없는 오류가 발생했습니다.',
              actionLabel: '다시 시도',
              onAction: () => setState(_loadMovies),
            );
          }

          final movies = snapshot.data ?? const <Movie>[];
          if (movies.isEmpty) {
            return const _MessageView(message: '표시할 영화가 없습니다.');
          }

          return _buildMovieList(movies, margin);
        },
      ),
    );
  }

  Widget _buildMovieList(List<Movie> movies, double margin) {
    final genres = [
      _allGenres,
      ...{for (final movie in movies) movie.genre},
    ];
    final filteredMovies = _selectedGenre == _allGenres
        ? movies
        : movies.where((movie) => movie.genre == _selectedGenre).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: margin),
            itemCount: genres.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final genre = genres[index];
              return _GenreChip(
                label: genre,
                selected: genre == _selectedGenre,
                onSelected: () => setState(() => _selectedGenre = genre),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(child: MovieGrid(movies: filteredMovies)),
      ],
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      backgroundColor: AppColors.black.withValues(alpha: 0.08),
      selectedColor: AppColors.violet,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.white : AppColors.black,
      ),
    );
  }
}
