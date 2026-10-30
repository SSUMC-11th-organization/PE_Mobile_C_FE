import 'package:flutter/material.dart';

import '../../data/mock_movies.dart';
import '../../theme/app_colors.dart';
import '../../widgets/movie/cards/movie_card.dart';
import '../../widgets/home/popular_movie_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final movie = movies.first;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MovieLog',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '오늘은 어떤\n영화를 볼까요?',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            MovieCard(movie: movie),
            const SizedBox(height: 32),
            const PopularMovieSection(),
          ],
        ),
      ),
    );
  }
}
