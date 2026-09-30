// 영화 상세 화면 구현
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_rating_input.dart';

const _averageRating = 4.5;

class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final int? movieId;

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = findMovieById(movieId);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Cinema Archive',
        centerTitle: true,
        onBack: () => _goBack(context),
        actions: [
          IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(
              'assets/icons/share.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.violet,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
      body: movie == null
          ? const Center(
              child: Text('영화를 찾을 수 없어요', style: AppTextStyles.bodyMedium),
            )
          : ListView(
              children: [
                AspectRatio(
                  aspectRatio: 2 / 3,
                  child: Image.asset(movie.posterAsset, fit: BoxFit.cover),
                ),
                _MovieInfo(movie: movie),
              ],
            ),
      bottomNavigationBar: movie == null ? null : const _BottomActions(),
    );
  }
}

class _MovieInfo extends StatelessWidget {
  const _MovieInfo({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMargin(context),
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(movie.title, style: AppTextStyles.headlineLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${movie.year} • ${movie.genre}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              RatingBarIndicator(
                rating: _averageRating,
                itemCount: 5,
                itemSize: 20,
                itemBuilder: (context, _) =>
                    const Icon(Icons.star, color: AppColors.violet),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _averageRating.toStringAsFixed(1),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Chip(
            label: Text(movie.genre),
            backgroundColor: colors.onSurface.withValues(alpha: 0.08),
            side: BorderSide.none,
            shape: const StadiumBorder(),
            labelStyle: const TextStyle(
              color: AppColors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatefulWidget {
  const _BottomActions();

  @override
  State<_BottomActions> createState() => _BottomActionsState();
}

class _BottomActionsState extends State<_BottomActions> {
  bool _isFavorite = false;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _showSnackBar(_isFavorite ? '즐겨찾기에 추가했어요' : '즐겨찾기에서 삭제했어요');
  }

  Future<void> _openRatingDialog() async {
    final rating = await showDialog<double>(
      context: context,
      builder: (_) => const _RatingDialog(),
    );
    if (rating == null || !mounted) return;
    _showSnackBar('${rating.toStringAsFixed(1)}점을 남겼어요');
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.gray.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMargin(context),
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _toggleFavorite,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.violet,
                      side: const BorderSide(color: AppColors.violet),
                      shape: const StadiumBorder(),
                    ),
                    icon: Icon(
                      _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      size: 20,
                    ),
                    label: const Text('즐겨찾기'),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _openRatingDialog,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.violet,
                      foregroundColor: AppColors.white,
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.rate_review_outlined, size: 20),
                    label: const Text('평점 남기기'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingDialog extends StatefulWidget {
  const _RatingDialog();

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  double _rating = 3;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('평점 남기기'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MovieRatingInput(
            rating: _rating,
            onChanged: (value) => setState(() => _rating = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${_rating.toStringAsFixed(1)}점',
            style: AppTextStyles.titleMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _rating),
          style: FilledButton.styleFrom(backgroundColor: AppColors.violet),
          child: const Text('등록'),
        ),
      ],
    );
  }
}
