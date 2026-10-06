import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class SignupAppbar extends StatelessWidget implements PreferredSizeWidget {
  const SignupAppbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      toolbarHeight: 64,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Text(
        '회원가입',
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
