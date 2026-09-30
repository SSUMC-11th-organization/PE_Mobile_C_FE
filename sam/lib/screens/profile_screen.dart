// 프로필 화면 구현
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/stat_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _genres = ['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '내 프로필'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMargin(context),
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ProfileHeader(),
              const SizedBox(height: AppSpacing.lg),
              const Center(child: _EditProfileButton()),
              const SizedBox(height: AppSpacing.xl),
              const _ProfileStats(),
              const SizedBox(height: AppSpacing.xl),
              const _FavoriteGenresSection(genres: _genres),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 128,
                  height: 128,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary.withValues(alpha: 0.35),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/profile/profile_movielog.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary,
                      border: Border.all(color: colors.surface, width: 2),
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/movie.svg',
                      colorFilter: ColorFilter.mode(
                        colors.onPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text('무비러버', style: AppTextStyles.headlineLarge),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '좋아하는 영화를 기록하고 있어요',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        side: BorderSide(color: colors.primary),
        minimumSize: const Size(132, 42),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      child: const Text(
        '프로필 수정',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: StatItem(label: '본 영화', value: '342'),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatItem(label: '평점', value: '4.2'),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatItem(label: '즐겨찾기', value: '58'),
        ),
      ],
    );
  }
}

class _FavoriteGenresSection extends StatelessWidget {
  const _FavoriteGenresSection({required this.genres});

  final List<String> genres;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(
              'assets/icons/bookmark.svg',
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('선호하는 장르', style: AppTextStyles.titleMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final genre in genres)
              Chip(
                label: Text(genre),
                backgroundColor: colors.primary.withValues(alpha: 0.12),
                side: BorderSide.none,
                labelStyle: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
