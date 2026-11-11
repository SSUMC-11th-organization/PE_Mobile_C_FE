import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:movielog/theme/app_colors.dart';

class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.enabled = true,
  });

  final double rating;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return RatingBar(
      initialRating: rating,
      minRating: 1,
      allowHalfRating: false,
      itemCount: 5,
      itemSize: 40,
      ratingWidget: RatingWidget(
        full: const Icon(Icons.star, color: AppColors.primary),
        half: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary,
              Color(0xFFE0DDE8),
              Color(0xFFE0DDE8),
            ],
            stops: [0, 0.5, 0.5, 1],
          ).createShader(bounds),
          child: const Icon(Icons.star, color: Colors.white),
        ),
        empty: const Icon(Icons.star, color: Color(0xFFE0DDE8)),
      ),
      onRatingUpdate: onChanged,
    );
  }
}
