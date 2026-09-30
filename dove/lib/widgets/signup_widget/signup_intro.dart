import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';

class SignupIntro extends StatelessWidget {
  const SignupIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 356,
      height: 64,
      padding: EdgeInsets.only(bottom: 16),
      child: Text(
        '환영합니다!\n간단한 정보만 입력하고 시작해보세요.',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 16,
          height: 24 / 16,
          fontWeight: FontWeight(500),
        ),
      ),
    );
  }
}
