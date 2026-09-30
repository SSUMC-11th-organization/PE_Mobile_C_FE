import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';

class StartMiddleLine extends StatelessWidget {
  const StartMiddleLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 358,
      height: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '영화의 순간을\n기록하세요',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.copyWith(
              fontSize: 28,
              height: 36 / 28,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: 0.25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
