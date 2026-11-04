import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../tmdb_poster_image.dart';

class PopularMovieSection extends StatelessWidget {
  const PopularMovieSection({
    super.key,
    required this.movies,
  });

  final List<TmdbMovieDto> movies;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '인기 영화',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/movies'),
              child: const Text('전체보기 ›'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (context, index) =>
            const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final movie = movies[index];
              final releaseDate = movie.releaseDate ?? '';
              final year = releaseDate.length >= 4
                  ? releaseDate.substring(0, 4)
                  : '';

              return GestureDetector(
                onTap: () => context.push(
                  '/movies/${movie.id}',
                  extra: movie,
                ),
                child: SizedBox(
                  width: 148,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: TmdbPosterImage(
                          posterPath: movie.posterPath,
                          width: 148,
                          height: 160,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movie.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        [
                          if (year.isNotEmpty) year,
                          'TMDB ${movie.voteAverage.toStringAsFixed(1)} / 10',
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}