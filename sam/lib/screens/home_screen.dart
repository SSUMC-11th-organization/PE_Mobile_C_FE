// 홈 화면 구현
import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenMargin(context),
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '오늘은 어떤\n영화를 볼까요?',
                style: AppTextStyles.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              MovieCard(movie: movies.first),
            ],
          ),
        ),
      ),
    );
  }
}
