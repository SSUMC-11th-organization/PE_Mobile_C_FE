// 프로필 화면 구현
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/stat_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _genres = ['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '내 프로필',
        actions: [
          TextButton(
            onPressed: () => context.read<AuthViewModel>().logout(),
            style: TextButton.styleFrom(foregroundColor: AppColors.violet),
            child: const Text('로그아웃'),
          ),
        ],
      ),
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
              const SizedBox(height: AppSpacing.lg),
              const _MyRatingsMenu(),
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
    final member = context.select<AuthViewModel, (String, String)?>(
      (auth) => auth.member == null
          ? null
          : (auth.member!.nickname, auth.member!.email),
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 128,
            height: 128,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.violet,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/profile/profile_movielog.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 내 정보(GET me)를 받기 전에는 빈 자리 대신 안내 문구를 보여 줌
          Text(
            member?.$1 ?? '내 정보를 불러오는 중이에요',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (member != null) Text(member.$2, style: AppTextStyles.bodySmall),
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
    // 수정 화면은 현재 닉네임이 필요하므로 내 정보가 있을 때만 켭니다.
    final hasMember = context.select<AuthViewModel, bool>(
      (auth) => auth.member != null,
    );
    return TextButton(
      onPressed: hasMember ? () => context.push('/my/profile/edit') : null,
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        side: BorderSide(color: hasMember ? colors.primary : AppColors.gray),
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
        Text('선호하는 장르', style: AppTextStyles.titleMedium),
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

class _MyRatingsMenu extends StatelessWidget {
  const _MyRatingsMenu();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      title: const Text('내가 등록한 평점', style: AppTextStyles.bodyMedium),
      trailing: Icon(Icons.chevron_right, color: colors.primary),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
      ),
      onTap: () => context.push('/my/ratings'),
    );
  }
}
