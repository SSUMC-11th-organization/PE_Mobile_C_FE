import 'package:flutter/material.dart';

import '../../../data/mock_movies.dart';
import 'movie_card.dart';

class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  final List<Movie> movies; // 전달받은 영화 List를 관리

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      // 선택한 장르에 영화가 한 편뿐이어도 당겨서 새로고침 가능.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: movies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.6,
      ),
      itemBuilder: (context, index) =>
          MovieCard(movie: movies[index], compact: true),
    );
  }
}
