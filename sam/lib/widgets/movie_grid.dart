// 영화 포스터 2열 그리드 위젯
import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../theme/app_theme.dart';
import 'movie_poster_card.dart';

class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    final margin = AppSpacing.screenMargin(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.md;
        final itemWidth = (constraints.maxWidth - margin * 2 - spacing) / 2;

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(margin, 0, margin, AppSpacing.lg),
          itemCount: movies.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: spacing,
            mainAxisSpacing: AppSpacing.lg,
            // 포스터(2:3) 높이 + 제목·부가정보 높이
            mainAxisExtent: itemWidth * 3 / 2 + 64,
          ),
          itemBuilder: (context, index) =>
              MoviePosterCard(movie: movies[index]),
        );
      },
    );
  }
}
