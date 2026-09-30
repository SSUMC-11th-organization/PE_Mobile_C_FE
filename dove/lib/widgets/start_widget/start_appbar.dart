import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';

class StartAppbar extends StatelessWidget implements PreferredSizeWidget {
  const StartAppbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 40,
      centerTitle: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.background,
      scrolledUnderElevation: 0,
      title: Text(
        'FLUTTER 0주차',
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 16 / 11,
          letterSpacing: 0.55,
          color: const Color(0xFF494551),
        ),
      ),
    );
  }
}
