// 영화 목록 화면 구현
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/mock_movies.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_poster_card.dart';

const _allGenres = '전체';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  String _selectedGenre = _allGenres;

  List<String> get _genres => [
    _allGenres,
    ...{for (final movie in movies) movie.genre},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredMovies = _selectedGenre == _allGenres
        ? movies
        : movies.where((movie) => movie.genre == _selectedGenre).toList();
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: margin),
              itemCount: _genres.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final genre = _genres[index];
                return _GenreChip(
                  label: genre,
                  selected: genre == _selectedGenre,
                  onSelected: () => setState(() => _selectedGenre = genre),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = AppSpacing.md;
                final itemWidth =
                    (constraints.maxWidth - margin * 2 - spacing) / 2;

                return GridView.builder(
                  padding: EdgeInsets.fromLTRB(
                    margin,
                    0,
                    margin,
                    AppSpacing.lg,
                  ),
                  itemCount: filteredMovies.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: AppSpacing.lg,
                    // 포스터(2:3) 높이 + 제목·부가정보 높이
                    mainAxisExtent: itemWidth * 3 / 2 + 64,
                  ),
                  itemBuilder: (context, index) =>
                      MoviePosterCard(movie: filteredMovies[index]),
                );
              },
            ),
          ),
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
