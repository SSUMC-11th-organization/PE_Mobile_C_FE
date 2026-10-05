import 'package:flutter/material.dart';

import '../../widgets/common/common_app_bar.dart';
import '../../widgets/profile/edit_profile_button.dart';
import '../../widgets/profile/favorite_genres.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/stat_item.dart';

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

                const FavoriteGenres(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
