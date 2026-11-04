// 영화 목록 화면 구현
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../view_models/movie_list_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_status_views.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          Consumer<MovieListViewModel>(
            builder: (context, viewModel, child) {
              // 장르 목록을 받기 전(첫 로딩·장르 API 실패)에는 Chip을 숨김
              if (viewModel.genres.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _GenreChips(viewModel: viewModel),
              );
            },
          ),
          Expanded(
            child: Consumer<MovieListViewModel>(
              builder: (context, viewModel, child) {
                return switch (viewModel.status) {
                  MovieListLoadStatus.idle ||
                  MovieListLoadStatus.loading => const MovieListLoading(),
                  MovieListLoadStatus.error => MovieListError(
                    message: viewModel.message,
                    // 장르 목록부터 실패했으면 처음부터, 아니면 선택한 장르로 다시 요청
                    onRetry: () => viewModel.genres.isEmpty
                        ? viewModel.loadInitial()
                        : viewModel.selectGenre(viewModel.selectedGenreId),
                  ),
                  MovieListLoadStatus.empty => const MovieListEmpty(),
                  MovieListLoadStatus.success => MovieGrid(
                    movies: viewModel.movies,
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreChips extends StatelessWidget {
  const _GenreChips({required this.viewModel});

  final MovieListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    // '전체'는 장르 id null
    final chips = <(int?, String)>[
      (null, '전체'),
      for (final genre in viewModel.genres) (genre.id, genre.name),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin(context),
        ),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final (genreId, name) = chips[index];
          return _GenreChip(
            label: name,
            selected: genreId == viewModel.selectedGenreId,
            // 요청 중에는 null을 넘겨 Chip을 비활성화 (장르 변경 불가)
            onSelected: viewModel.status == MovieListLoadStatus.loading
                ? null
                : () => viewModel.selectGenre(genreId),
          );
        },
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
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected == null ? null : (_) => onSelected!(),
      showCheckmark: false,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      backgroundColor: AppColors.black.withValues(alpha: 0.08),
      selectedColor: AppColors.violet,
      // 요청 중(비활성) 상태에서도 선택한 장르가 구분되도록
      disabledColor: selected
          ? AppColors.violet.withValues(alpha: 0.5)
          : AppColors.black.withValues(alpha: 0.04),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.white : AppColors.black,
      ),
    );
  }
}
