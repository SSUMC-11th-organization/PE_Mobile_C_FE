import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';

class GenreTag extends StatelessWidget {
  const GenreTag({super.key, required this.genre});

  final String genre;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFE9DDFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        genre,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
