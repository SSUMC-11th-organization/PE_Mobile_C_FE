import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../view_models/auth_view_model.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final nickname = context.select<AuthViewModel, String?>(
      (auth) => auth.member?.nickname,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 128,
          height: 128,
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Color(0xFFD0BCFF),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/profile/profile_movielog.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          nickname ?? '회원 정보 불러오는 중',
          style: Theme.of(context).textTheme.titleLarge,
        ),

        const SizedBox(height: 8),

        Text(
          '매주 주말엔 영화관으로 출근하는 프로 관람객.\n'
          '좋은 영화를 보고 기록하는 것을 좋아합니다.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
