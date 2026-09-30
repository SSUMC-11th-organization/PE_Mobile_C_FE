import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class StatisticsWidget extends StatelessWidget {
  const StatisticsWidget({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 114,
      height: 86,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3F0),
        border: Border.all(color: const Color(0xFFE9DDFF), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              fontSize: 22,
              height: 28 / 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
