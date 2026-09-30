import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import 'profile_genre.dart';

class ProfileGenre extends StatelessWidget {
  const ProfileGenre({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 358,
      height: 72,
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "선호하는 장르",
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            width: 358,
            height: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GenreTag(genre: "드라마"),
                SizedBox(width: 8),
                GenreTag(genre: "SF"),
                SizedBox(width: 8),
                GenreTag(genre: "애니메이션"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
