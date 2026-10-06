import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'profile_statistics_widget.dart';

class ProfileStatistics extends StatelessWidget {
  const ProfileStatistics({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: const Color(0xFFE9DDFF), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: StatisticsWidget(label: '본 영화', value: '342'),
          ),
          Expanded(
            child: StatisticsWidget(label: '평점', value: '4.2'),
          ),
          Expanded(
            child: StatisticsWidget(label: '즐겨찾기', value: '58'),
          ),
        ],
      ),
    );
  }
}
