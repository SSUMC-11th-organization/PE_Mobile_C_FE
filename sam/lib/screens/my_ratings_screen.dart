// 내가 등록한 평점 화면 (하단 탭 없이 전체 화면, 수정·삭제·선택 삭제)
import 'package:dio/dio.dart';
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
import '../widgets/loading_overlay.dart';
import '../widgets/loading_view.dart';
import '../widgets/movie_poster_image.dart';
import '../widgets/rating_dialog.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/my');
    }
  }

  Future<void> _confirmDeleteSelected(
    BuildContext context,
    MyRatingsViewModel viewModel,
  ) async {
    final count = viewModel.selectedRatingIds.length;
    final ok = await _confirm(context, '선택한 평점 $count개를 삭제할까요?');
    if (!ok || !context.mounted) return;
    await viewModel.deleteSelectedRatings();
    if (!context.mounted) return;
    _showSnackBar(context, viewModel.message ?? '평점 $count개를 삭제했어요');
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MyRatingsViewModel>();
    final isSelecting = viewModel.selectedRatingIds.isNotEmpty;

    // 선택 삭제 중에는 뒤로가기를 막습니다.
    return PopScope(
      canPop: !viewModel.isDeletingSelected,
      child: Scaffold(
        // 중앙 제목 + 왼쪽 BackButton, bottomNavigationBar는 전달하지 않음
        appBar: AppBar(
          centerTitle: true,
          leading: BackButton(onPressed: () => _goBack(context)),
          title: Text(
            isSelecting
                ? '${viewModel.selectedRatingIds.length}개 선택'
                : '내가 등록한 평점',
            style: AppTextStyles.titleLarge.copyWith(
              fontSize: 20,
              color: AppColors.violet,
            ),
          ),
          actions: [
            if (isSelecting) ...[
              TextButton(
                onPressed: viewModel.isDeletingSelected
                    ? null
                    : viewModel.clearSelection,
                child: const Text('취소'),
              ),
              IconButton(
                tooltip: '선택 삭제',
                onPressed: viewModel.isDeletingSelected
                    ? null
                    : () => _confirmDeleteSelected(context, viewModel),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
        body: SafeArea(
          child: LoadingOverlay(
            isLoading: viewModel.isDeletingSelected,
            child: switch (viewModel.status) {
              MyRatingsStatus.idle ||
              MyRatingsStatus.loading => const LoadingView(),
              MyRatingsStatus.empty => const EmptyView(
                message: '아직 등록한 평점이 없어요.\n영화를 보고 첫 평점을 남겨 보세요!',
              ),
              MyRatingsStatus.error => ErrorView(
                message:
                    viewModel.refreshWarning ??
                    viewModel.errorMessage ??
                    '평점을 불러오지 못했어요.',
                onRetry: viewModel.load,
              ),
              MyRatingsStatus.success => _RatingList(viewModel: viewModel),
            },
          ),
        ),
      ),
    );
  }
}

void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> _confirm(BuildContext context, String title) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class _RatingList extends StatelessWidget {
  const _RatingList({required this.viewModel});

  final MyRatingsViewModel viewModel;

  Future<void> _edit(BuildContext context, RatingDto rating) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => RatingDialog(
        initialScore: rating.score,
        initialComment: rating.comment,
        // 실패하면 400/403/404/409에 맞는 문구를 Dialog 안에 보여 줌
        errorMessageOf: (_) => viewModel.message,
        onSubmit: (score, comment) => viewModel.updateRating(
          ratingId: rating.ratingId,
          score: score,
          comment: comment,
        ),
      ),
    );
    if (saved == true && context.mounted) _showSnackBar(context, '평점을 수정했어요');
  }

  Future<void> _delete(BuildContext context, RatingDto rating) async {
    if (viewModel.isDeleting(rating.ratingId)) return;
    final ok = await _confirm(context, '이 평점을 삭제할까요?');
    if (!ok || !context.mounted || viewModel.isDeleting(rating.ratingId)) {
      return;
    }
    try {
      await viewModel.deleteRating(rating.ratingId);
      if (context.mounted) _showSnackBar(context, '평점을 삭제했어요');
    } on DioException {
      if (context.mounted) {
        _showSnackBar(context, viewModel.message ?? '평점을 삭제하지 못했어요.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratings = viewModel.ratings;
    final isSelecting = viewModel.selectedRatingIds.isNotEmpty;

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
          final movie = viewModel.moviesById[rating.movieId];
          return _RatingCard(
            rating: rating,
            movie: movie,
            isLoadingMovie: viewModel.isLoadingMovies,
            isSelecting: isSelecting,
            isSelected: viewModel.selectedRatingIds.contains(rating.ratingId),
            isDeleting: viewModel.isDeleting(rating.ratingId),
            // 선택 중이면 탭으로 선택을 바꾸고, 아니면 영화 상세로 이동
            onTap: isSelecting
                ? () => viewModel.toggleSelected(rating.ratingId)
                : movie == null
                ? null
                : () => context.push('/movies/${movie.id}', extra: movie),
            onLongPress: () => viewModel.toggleSelected(rating.ratingId),
            onEdit: () => _edit(context, rating),
            onDelete: () => _delete(context, rating),
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
    required this.isSelecting,
    required this.isSelected,
    required this.isDeleting,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
  });

  final RatingDto rating;
  // TMDB 조회 전이거나 찾지 못했으면 null
  final Movie? movie;
  // TMDB 영화 정보를 받아오는 중이면 '정보 없음' 대신 빈칸으로 둠
  final bool isLoadingMovie;
  // 길게 눌러 선택 모드에 들어가면 수정·삭제 버튼 대신 체크 표시를 보여 줌
  final bool isSelecting;
  final bool isSelected;
  // 삭제 요청 중이면 버튼 대신 로딩 표시 (연속 탭 방지)
  final bool isDeleting;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
        side: BorderSide(
          color: isSelected ? AppColors.violet : _cardBorder,
          width: isSelected ? 2 : 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
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
              if (isSelecting)
                Checkbox(value: isSelected, onChanged: (_) => onTap?.call())
              else if (isDeleting)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '수정',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      color: AppColors.violet,
                    ),
                    IconButton(
                      tooltip: '삭제',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      color: AppColors.violet,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
