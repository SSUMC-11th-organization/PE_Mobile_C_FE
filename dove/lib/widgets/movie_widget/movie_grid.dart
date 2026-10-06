import 'package:flutter/material.dart';

import '../../models/movie.dart';
import 'movie_card.dart';

class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: movies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) => MovieCard(movie: movies[index]),
    );
  }
}
