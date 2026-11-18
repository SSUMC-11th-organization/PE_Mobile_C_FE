import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final member = context.select<AuthViewModel, MemberInfo?>((a) => a.member);
    final memberStatus = context.select<AuthViewModel, MemberLoadStatus>(
      (a) => a.memberStatus,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: CommonAppBar(
        title: '내 프로필',
        centerTitle: false,
        titleStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.55,
          color: Color(0xFF4F378A),
        ),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            icon: const Icon(Icons.logout),
            // 이동 코드는 쓰지 않습니다. signedOut이 되면 Router가 /login으로 보냅니다.
            onPressed: () => context.read<AuthViewModel>().logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: member != null
            ? const ProfileBody()
            : memberStatus == MemberLoadStatus.error
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('내 정보를 불러오지 못했어요.'),
                      const SizedBox(height: 12),
                      MovieLogButton(
                        label: '다시 시도',
                        onPressed: () => context
                            .read<AuthViewModel>()
                            .loadMember(force: true),
                      ),
                    ],
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const ProfileHeader(),
            const SizedBox(height: 32),
            const ProfileStat(),
            const SizedBox(height: 24),
            ListTile(
              onTap: () => context.push('/my/ratings'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.outline, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              title: const Text('내가 등록한 평점'),
              titleTextStyle: AppTextStyles.titleMedium.copyWith(
                color: AppColors.onSurface,
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.outline, width: 1),
              ),
              title: const Text('내 즐겨찾기'),
              titleTextStyle: AppTextStyles.titleMedium.copyWith(
                color: AppColors.onSurface,
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.primary,
              ),
              onTap: () => context.push('/my/favorites'),
            ),
            const SizedBox(height: 32),
            const FavoriteGenres(),
          ],
        ),
      ),
    );
  }
}

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.centerTitle = false,
    this.titleStyle,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style:
            titleStyle ??
            AppTextStyles.titleLarge.copyWith(color: AppColors.violet),
      ),
      centerTitle: centerTitle,
      leading: onBack == null
          ? null
          : IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final member = context.select<AuthViewModel, MemberInfo?>((a) => a.member);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ProfileAvatar(
          imagePath: 'assets/images/profile/profile_movielog.jpg',
        ),
        const SizedBox(height: 8),
        Text(
          member?.nickname ?? '불러오는 중…',
          textAlign: TextAlign.center,
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.onSurface),
        ),
        if (member != null) ...[
          const SizedBox(height: 4),
          Text(
            formatJoinedDate(member.createdAt), // 예: 2026.10.10 가입
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        // v7 GET me에는 소개글 필드가 없어서, 그 자리에 이메일을 보여줍니다.
        Text(
          member?.email ?? '',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.only(top: 8),
          child: ElevatedButton(
            // member가 없으면 비활성화합니다. (프로필 수정 화면이 member를 필요로 함)
            onPressed: member == null
                ? null
                : () => context.push('/my/profile/edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: AppColors.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: AppColors.onPrimaryContainer),
            ),
            child: const Text('프로필 수정'),
          ),
        ),
      ],
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outline, width: 2),
      ),
      child: CircleAvatar(
        radius: 62,
        backgroundColor: AppColors.surfaceContainer,
        backgroundImage: imagePath != null ? AssetImage(imagePath!) : null,
        child: imagePath == null
            ? Icon(Icons.person, size: 62, color: AppColors.onSurfaceVariant)
            : null,
      ),
    );
  }
}

class ProfileStat extends StatelessWidget {
  const ProfileStat({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: _stats
            .map(
              (stat) => Expanded(
                child: StatItem(label: stat.label, value: stat.value),
              ),
            )
            .expand((widget) => [widget, const SizedBox(width: 8)])
            .toList(),
      ),
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value);
  final String label;
  final String value;
}

const _stats = [
  _StatData('본 영화', '24'),
  _StatData('평점', '4.2'),
  _StatData('즐겨찾기', '58'),
];

class StatItem extends StatelessWidget {
  const StatItem({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.primaryContainer),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class FavoriteGenres extends StatelessWidget {
  const FavoriteGenres({super.key});

  @override
  Widget build(BuildContext context) {
    const genres = ['드라마', 'SF', '애니메이션'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선호하는 장르',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: 16),
        Row(
          spacing: 8,
          children: genres.map((genre) => GenreTag(label: genre)).toList(),
        ),
      ],
    );
  }
}

class GenreTag extends StatelessWidget {
  const GenreTag({super.key, required this.label, this.bold = false});

  final String label;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: AppTextStyles.bodySmall.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.onPrimaryContainer,
      ),
      labelPadding: EdgeInsets.zero,
      backgroundColor: AppColors.primaryContainer,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
    );
  }
}

String formatJoinedDate(DateTime createdAt) {
  final d = createdAt.toLocal();
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}.$mm.$dd 가입';
}
