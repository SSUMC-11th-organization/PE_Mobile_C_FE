import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/movie_widget/movie_detail_action_bar.dart';
import '../widgets/movie_widget/movie_detail_info.dart';
import '../widgets/movie_widget/movie_poster.dart';
import '../widgets/movie_widget/rating_dialog.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final String movieId;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;
  double? _myRating;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _showMessage(_isFavorite ? '즐겨찾기에 추가했어요.' : '즐겨찾기에서 삭제했어요.');
  }

  Future<void> _rate() async {
    final rating = await showDialog<double>(
      context: context,
      builder: (context) => RatingDialog(initialRating: _myRating ?? 0),
    );
    if (rating == null || !mounted) return;

    setState(() => _myRating = rating);
    _showMessage('별점 $rating점을 남겼어요.');
  }

  @override
  Widget build(BuildContext context) {
    final movie = findMovieById(widget.movieId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          // 직접 주소로 들어와 돌아갈 화면이 없으면 홈으로 보낸다
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        title: Text(
          'Cinema Archive',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => debugPrint('공유 버튼을 눌렀습니다.'),
            icon: const Icon(Icons.share, size: 20, color: AppColors.primary),
          ),
        ],
      ),
      body: movie == null
          ? const Center(child: Text('영화를 찾을 수 없어요.'))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 3 / 2,
                          child: MoviePoster(movie: movie, borderRadius: 0),
                        ),
                        MovieDetailInfo(movie: movie, myRating: _myRating),
                      ],
                    ),
                  ),
                ),
                MovieDetailActionBar(
                  isFavorite: _isFavorite,
                  onFavoritePressed: _toggleFavorite,
                  onRatePressed: _rate,
                ),
              ],
            ),
    );
  }
}
