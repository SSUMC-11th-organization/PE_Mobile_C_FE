import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../../theme/app_colors.dart';
import '../../view_models/movie_home_view_model.dart';
import '../../widgets/home/popular_movie_section.dart';
import '../../widgets/tmdb_poster_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MovieLog',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '오늘은 어떤\n영화를 볼까요?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Consumer<MovieHomeViewModel>(
              builder: (context, viewModel, child) {
                switch (viewModel.status) {
                  case MovieHomeLoadStatus.idle:
                  case MovieHomeLoadStatus.loading:
                    return const SizedBox(
                      height: 220,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                  case MovieHomeLoadStatus.error:
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Text(
                            viewModel.message ??
                                '인기 영화를 불러오지 못했어요.',
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () {
                              context
                                  .read<MovieHomeViewModel>()
                                  .loadPopular();
                            },
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    );

                  case MovieHomeLoadStatus.empty:
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('인기 영화가 없습니다.'),
                      ),
                    );

                  case MovieHomeLoadStatus.success:
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFeaturedMovie(
                          context,
                          viewModel.popularMovies.first,
                        ),
                        const SizedBox(height: 32),
                        PopularMovieSection(
                          movies: viewModel.popularMovies,
                        ),
                      ],
                    );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedMovie(
      BuildContext context,
      TmdbMovieDto movie,
      ) {
    return GestureDetector(
      onTap: () => context.push(
        '/movies/${movie.id}',
        extra: movie,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 440,
          child: Stack(
            fit: StackFit.expand,
            children: [
              TmdbPosterImage(
                posterPath: movie.posterPath,
                width: double.infinity,
                height: 440,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black87,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TMDB ${movie.voteAverage.toStringAsFixed(1)} / 10',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Text(
                          '상세보기',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}