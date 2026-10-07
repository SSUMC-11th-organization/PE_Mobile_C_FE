import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/movie.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'movie_poster.dart';

/// 홈의 '인기 영화' 가로 스크롤 목록
class PopularMovieList extends StatelessWidget {
  const PopularMovieList({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: movies.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final movie = movies[index];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push('/movies/${movie.id}'),
            child: SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: MoviePoster(movie: movie, borderRadius: 12)),
                  const SizedBox(height: 6),
                  Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 16 / 12,
                    ),
                  ),
                  Text(
                    '★ ${movie.rating}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
