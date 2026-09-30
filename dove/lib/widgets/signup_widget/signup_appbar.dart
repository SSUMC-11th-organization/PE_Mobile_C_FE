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
      leading: IconButton(
        onPressed: () {
          debugPrint("뒤로가기 버튼을 눌렀습니다");
        },
        icon: Icon(Icons.arrow_back, size: 16, color: AppColors.black),
      ),
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
