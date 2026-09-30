import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/profile_widget/profile_appbar.dart';
import '../widgets/profile_widget/profile_header.dart';
import '../widgets/profile_widget/profile_statistics.dart';
import '../widgets/profile_widget/profile_prefered_genre.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ProfileAppbar(), //AppBar구성
      backgroundColor: AppColors.background, // 배경색
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ProfileHeader(), // 프로필 헤더
              SizedBox(height: 32),
              ProfileStatistics(), // 통계 카드
              SizedBox(height: 32),
              ProfileGenre(),
            ],
          ),
        ),
      ),
    );
  }
}
