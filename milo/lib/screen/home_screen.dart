import 'package:flutter/material.dart';
import 'package:movielog/data/mock_movie.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/widgets/home/featured_movie_banner.dart';
import 'package:movielog/widgets/home/popular_movies_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final featuredMovie = findMovieById(1)!;
    final popularMovies = movies.where((m) => m.id != 1).take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MovieLog',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.55,
                      color: Color(0xFF4F378A),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF4F378A),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '오늘은 어떤 영화를 볼까요?',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.7,
                          color: Color(0xFF1D1B20),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: FeaturedMovieBanner(movie: featuredMovie),
                    ),
                    PopularMoviesSection(movies: popularMovies),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
