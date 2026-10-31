// 영화 포스터 이미지 위젯 (포스터가 없거나 로드에 실패하면 placeholder 표시)
import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../theme/app_colors.dart';

class MoviePosterImage extends StatelessWidget {
  const MoviePosterImage({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final posterUrl = movie.posterUrl;
    if (posterUrl != null) {
      return Image.network(
        posterUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const PosterPlaceholder(),
      );
    }

    final posterAsset = movie.posterAsset;
    if (posterAsset != null) {
      return Image.asset(posterAsset, fit: BoxFit.cover);
    }

    return const PosterPlaceholder();
  }
}

class PosterPlaceholder extends StatelessWidget {
  const PosterPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.gray.withValues(alpha: 0.3),
      child: const Center(
        child: Icon(Icons.movie_outlined, size: 40, color: AppColors.gray),
      ),
    );
  }
}
