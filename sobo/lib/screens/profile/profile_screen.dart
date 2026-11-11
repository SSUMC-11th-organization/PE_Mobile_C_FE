import 'package:flutter/material.dart';

import '../../widgets/common/common_app_bar.dart';
import '../../widgets/profile/edit_profile_button.dart';
import '../../widgets/profile/favorite_genres.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/stat_item.dart';

import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: '내 프로필'),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ProfileHeader(),

                Container(
                  margin: const EdgeInsets.only(top: 24, bottom: 32),
                  child: const Center(child: EditProfileButton()),
                ),

                const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: StatItem(label: '본 영화', value: '342'),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: StatItem(label: '평점', value: '4.2'),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: StatItem(label: '즐겨찾기', value: '58'),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD5C7E8),
                      width: 1.5,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    title: const Text(
                      '내가 등록한 평점',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF6750A4),
                      size: 28,
                    ),
                    onTap: () => context.push('/my/ratings'),
                  ),
                ),
                const SizedBox(height: 32),
                const FavoriteGenres(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
