import 'package:flutter/material.dart';
import 'package:movielog/data/mock_movie.dart';
import 'package:movielog/widgets/movie/movie_grid_card.dart';

class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: movies.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 24,
          childAspectRatio: 171 / 316.5,
        ),
        itemBuilder: (context, index) {
          return MovieGridCard(movie: movies[index]);
        },
        physics: const AlwaysScrollableScrollPhysics(),
      ),
    );
  }
}
