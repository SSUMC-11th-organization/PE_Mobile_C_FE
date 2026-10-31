// 홈 화면 구현
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../view_models/movie_home_view_model.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_poster_card.dart';

const _posterWidth = 120.0;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MovieHomeViewModel>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMargin(context),
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '오늘은 어떤\n영화를 볼까요?',
                style: AppTextStyles.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              switch (viewModel.status) {
                MovieHomeLoadStatus.idle || MovieHomeLoadStatus.loading =>
                  const SizedBox(height: 300, child: LoadingView()),
                MovieHomeLoadStatus.error => SizedBox(
                  height: 300,
                  child: ErrorView(
                    message: viewModel.message ?? '알 수 없는 오류가 발생했습니다.',
                    onRetry: viewModel.loadPopular,
                  ),
                ),
                MovieHomeLoadStatus.empty => const SizedBox(
                  height: 300,
                  child: EmptyView(message: '표시할 영화가 없습니다.'),
                ),
                MovieHomeLoadStatus.success => _PopularMovies(
                  movies: viewModel.popularMovies
                      .map((dto) => dto.toMovie())
                      .toList(),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularMovies extends StatelessWidget {
  const _PopularMovies({required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    // 1위는 큰 카드로, 나머지는 가로 목록으로 표시
    final others = movies.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MovieCard(movie: movies.first),
        if (others.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const Text('지금 인기 있는 영화', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            // 포스터(2:3) 높이 + 제목·부가정보 높이
            height: _posterWidth * 3 / 2 + 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: others.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) => SizedBox(
                width: _posterWidth,
                child: MoviePosterCard(movie: others[index]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
