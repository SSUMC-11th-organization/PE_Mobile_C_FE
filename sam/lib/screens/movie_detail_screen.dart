// 영화 상세 화면 구현
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/sign_up_view_model.dart' show SubmitStatus;
import '../widgets/common_app_bar.dart';
import '../widgets/movie_poster_image.dart';
import '../widgets/rating_dialog.dart';

const _averageRating = 4.5;

// MovieDetailLoader가 영화를 준비한 뒤 MovieDetailViewModel과 함께 표시합니다.
class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({super.key});

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = context.read<MovieDetailViewModel>().movie;

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
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: MoviePosterImage(movie: movie),
          ),
          _MovieInfo(movie: movie),
        ],
      ),
      bottomNavigationBar: const _BottomActions(),
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
            movie.year == null ? movie.genre : '${movie.year} • ${movie.genre}',
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
    final viewModel = context.read<MovieDetailViewModel>();
    // 학습용 회원 ID가 없으면 Dialog를 열지 않고 안내만 합니다.
    if (viewModel.memberId == null) {
      _showSnackBar('먼저 회원가입을 완료해 주세요.');
      return;
    }

    var savedScore = 0;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => RatingDialog(
        onSubmit: (score, comment) async {
          await viewModel.createRating(score: score, comment: comment);
          // 실패하면 던져서 Dialog가 열린 채로 에러 문구를 보여 주게 합니다.
          if (viewModel.submitStatus != SubmitStatus.success) {
            final message = viewModel.submitMessage ?? '평점을 등록하지 못했어요.';
            if (mounted) _showSnackBar(message);
            throw StateError(message);
          }
          savedScore = score;
        },
      ),
    );
    if (saved != true || !mounted) return;
    _showSnackBar('$savedScore점을 남겼어요');
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
