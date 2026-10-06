import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../models/movie.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class MovieDetailInfo extends StatelessWidget {
  const MovieDetailInfo({super.key, required this.movie, this.myRating});

  final Movie movie;
  final double? myRating;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movie.title,
            style: AppTextStyles.titleLarge.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(movie.detailMeta, style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: [
              RatingBarIndicator(
                rating: movie.rating,
                itemCount: 5,
                itemSize: 18,
                itemBuilder: (context, index) =>
                    const Icon(Icons.star, color: AppColors.star),
              ),
              const SizedBox(width: 8),
              Text(
                '${movie.rating} (${_withComma(movie.ratingCount)})',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
              ),
            ],
          ),
          if (myRating != null) ...[
            const SizedBox(height: 8),
            Text(
              '내 별점 $myRating점',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final genre in movie.genres)
                Chip(
                  label: Text(genre),
                  side: BorderSide.none,
                  backgroundColor: AppColors.secondaryContainer,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const Divider(height: 32),
          Text('시놉시스', style: AppTextStyles.titleMedium.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            movie.synopsis,
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }

  static String _withComma(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
}
