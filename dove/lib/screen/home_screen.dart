import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/movie_widget/home_featured_card.dart';
import '../widgets/movie_widget/popular_movie_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 홈에서는 뒤로 가기로 이전 화면(회원가입)에 돌아가지 못하게 막는다
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'MovieLog',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: () => debugPrint('검색 버튼을 눌렀습니다.'),
              icon: const Icon(Icons.search, color: AppColors.primary),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘은 어떤\n영화를 볼까요?',
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 16),
                    HomeFeaturedCard(movie: featuredMovie),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('인기 영화', style: AppTextStyles.titleMedium),
                        TextButton(
                          onPressed: () => context.go('/movies'),
                          child: const Text('전체보기 ›'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopularMovieList(movies: mockMovies.skip(6).toList()),
            ],
          ),
        ),
      ),
    );
  }
}
