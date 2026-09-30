import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ProfileAppbar extends StatelessWidget implements PreferredSizeWidget {
  const ProfileAppbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      toolbarHeight: 64,
      centerTitle: false,
      titleSpacing: 16,
      title: Text(
        '내 프로필',
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          height: 28 / 22,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
