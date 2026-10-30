import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/tmdb_movie_dto.dart';
import '../../tmdb_poster_image.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({
    super.key,
    required this.movie,
  });

  final TmdbMovieDto movie;

  String get releaseYear {
    final date = movie.releaseDate;

    if (date == null || date.length < 4) {
      return '개봉일 미정';
    }

    return date.substring(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(
          '/movies/${movie.id}',
          extra: movie,
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TmdbPosterImage(
                posterPath: movie.posterPath,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    releaseYear,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${movie.voteAverage.toStringAsFixed(1)} / 10',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}