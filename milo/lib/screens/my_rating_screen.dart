import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/movie_card.dart';
import 'package:provider/provider.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        centerTitle: true,
        title: const Text('내가 등록한 평점'),
      ),
      body: SafeArea(
        child: Consumer<MyRatingsViewModel>(
          builder: (context, viewModel, child) {
            return switch (viewModel.status) {
              MyRatingsLoadStatus.idle || MyRatingsLoadStatus.loading =>
                const Center(child: CircularProgressIndicator()),
              MyRatingsLoadStatus.empty => const Center(
                child: Text('아직 등록한 평점이 없어요.'),
              ),
              MyRatingsLoadStatus.error => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(viewModel.message ?? '평점을 불러오지 못했어요.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: viewModel.load,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
              MyRatingsLoadStatus.success => Column(
                children: [
                  if (viewModel.message != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: AppColors.primaryContainer,
                      child: Text(
                        viewModel.message!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: viewModel.ratings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) =>
                          _RatingTile(entry: viewModel.ratings[index]),
                    ),
                  ),
                ],
              ),
            };
          },
        ),
      ),
    );
  }
}

class _RatingTile extends StatelessWidget {
  const _RatingTile({required this.entry});

  final RatingWithMovie entry;

  @override
  Widget build(BuildContext context) {
    final movie = entry.movie;
    final comment = entry.rating.comment;
    final score = entry.rating.score.toDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          // movie가 null이면 posterPath도 null이라 placeholder가 그려집니다.
          child: TmdbPosterImage(
            posterPath: movie?.posterPath,
            width: 72,
            height: 104,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movie?.title ?? '영화 정보를 불러올 수 없어요',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              if (movie == null)
                Text(
                  '영화 ID ${entry.rating.movieId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  RatingBarIndicator(
                    rating: score,
                    itemCount: 5,
                    itemSize: 18,
                    itemBuilder: (context, index) =>
                        const Icon(Icons.star, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(score.toString()),
                ],
              ),
              // comment가 null이면 아예 표시하지 않습니다.
              if (comment != null && comment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  comment,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
