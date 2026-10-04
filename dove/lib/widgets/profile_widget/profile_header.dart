import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 358,
      height: 310,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
            ),
            child: CircleAvatar(
              radius: 61,
              backgroundImage: AssetImage('assets/images/profile.png'),
            ),
          ),
          Container(
            child: Column(
              children: [
                Text(
                  '무비러버',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontSize: 22,
                    height: 28 / 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '매주 주말엔 영화관으로 출근하는 프로 관람객. 좋\n은 영화를 보고 기록하는 것을 좋아합니다.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton(
              onPressed: () {
                debugPrint('프로필 수정 버튼을 눌렀습니다.');
              },
              style: OutlinedButton.styleFrom(
                fixedSize: Size(127, 50),
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                '프로필 수정',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 16,
                  height: 24 / 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
