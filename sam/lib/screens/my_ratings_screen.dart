// 내가 등록한 평점 화면 (하단 탭 없이 전체 화면)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/movie.dart';
import '../data/models/rating_dto.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/movie_poster_image.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/my');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MyRatingsViewModel>();

    return Scaffold(
      // 중앙 제목 + 왼쪽 BackButton, bottomNavigationBar는 전달하지 않음
      appBar: AppBar(
        centerTitle: true,
        leading: BackButton(onPressed: () => _goBack(context)),
        title: Text(
          '내가 등록한 평점',
          style: AppTextStyles.titleLarge.copyWith(
            fontSize: 20,
            color: AppColors.violet,
          ),
        ),
      ),
      body: SafeArea(
        child: switch (viewModel.status) {
          MyRatingsStatus.idle ||
          MyRatingsStatus.loading => const LoadingView(),
          MyRatingsStatus.empty => const EmptyView(
            message: '아직 등록한 평점이 없어요.\n영화를 보고 첫 평점을 남겨 보세요!',
          ),
          MyRatingsStatus.error => ErrorView(
            message: viewModel.errorMessage ?? '평점을 불러오지 못했어요.',
            onRetry: viewModel.load,
          ),
          MyRatingsStatus.success => _RatingList(viewModel: viewModel),
        },
      ),
    );
  }
}

class _RatingList extends StatelessWidget {
  const _RatingList({required this.viewModel});

  final MyRatingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final ratings = viewModel.ratings;

    return RefreshIndicator(
      onRefresh: viewModel.load,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin(context),
          vertical: AppSpacing.lg,
        ),
        itemCount: ratings.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final rating = ratings[index];
          return _RatingCard(
            rating: rating,
            movie: viewModel.moviesById[rating.movieId],
            isLoadingMovie: viewModel.isLoadingMovies,
          );
        },
      ),
    );
  }
}

// Figma: 테두리 카드 안에 포스터 · 제목 · '별점 n / 5' · 한줄평
class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.rating,
    required this.movie,
    required this.isLoadingMovie,
  });

  final RatingDto rating;
  // TMDB 조회 전이거나 찾지 못했으면 null
  final Movie? movie;
  // TMDB 영화 정보를 받아오는 중이면 '정보 없음' 대신 빈칸으로 둠
  final bool isLoadingMovie;

  static const _cardBorder = Color(0xFFDCD6E4);

  @override
  Widget build(BuildContext context) {
    final movie = this.movie;
    final comment = rating.comment?.trim() ?? '';
    // 한줄평이 있으면 한줄평, 없고 영화 정보도 못 찾았으면 안내 문구
    final description = comment.isNotEmpty
        ? comment
        : movie == null && !isLoadingMovie
        ? '포스터 정보 없음'
        : null;

    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _cardBorder, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: movie == null
            ? null
            : () => context.push('/movies/${movie.id}', extra: movie),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radius * 1.5),
                child: SizedBox(
                  width: 80,
                  height: 120,
                  child: movie == null
                      ? const ColoredBox(color: Color(0xFFD9D4E0))
                      : MoviePosterImage(movie: movie),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie?.title ?? '영화 #${rating.movieId}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '별점 ${rating.score} / 5',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.violet,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
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
