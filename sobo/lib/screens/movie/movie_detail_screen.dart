import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../../view_models/movie_detail_view_model.dart';
import '../../view_models/sign_up_view_model.dart';
import '../../widgets/movie/ratings/rating_dialog.dart';
import '../../widgets/tmdb_poster_image.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movie});

  final TmdbMovieDto movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool isFavorite = false;

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite ? '즐겨찾기에 추가했어요.' : '즐겨찾기를 해제했어요.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openRatingDialog() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        onSubmit: (score, comment) async {
          final viewModel = context.read<MovieDetailViewModel>();

          await viewModel.createRating(
            score: score,
            comment: comment,
          );

          if (viewModel.submitStatus != SubmitStatus.success) {
            final message = viewModel.submitMessage ?? '저장에 실패했습니다.';
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            }
            // 실패는 Dialog에도 전달하여 입력을 유지하고 재시도할 수 있게 합니다.
            throw StateError(message);
          }
        },
      ),
    );

    if (!mounted || saved != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final releaseDate = movie.releaseDate;

    final releaseText = releaseDate == null || releaseDate.isEmpty
        ? '개봉일 미정'
        : releaseDate;

    return Scaffold(
      appBar: AppBar(title: const Text('영화 상세')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TmdbPosterImage(
              posterPath: movie.posterPath,
              width: double.infinity,
              height: 380,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(releaseText),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      RatingBarIndicator(
                        // TMDB는 10점 만점, 별은 5개이므로 변환
                        rating: (movie.voteAverage / 2)
                            .clamp(0.0, 5.0)
                            .toDouble(),
                        itemCount: 5,
                        itemSize: 24,
                        itemBuilder: (context, index) {
                          return const Icon(Icons.star, color: Colors.amber);
                        },
                      ),
                      const SizedBox(width: 8),
                      Text('${movie.voteAverage.toStringAsFixed(1)} / 10'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '줄거리',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.overview.trim().isEmpty
                        ? '등록된 줄거리가 없습니다.'
                        : movie.overview,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _toggleFavorite,
                  icon: Icon(
                    isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  label: const Text('즐겨찾기'),
                ),
              ),
              const SizedBox(width: 12),
              Consumer<MovieDetailViewModel>(
                builder: (context, viewModel, child) {
                  final hasMember = viewModel.memberId != null;
                  final isSubmitting =
                      viewModel.submitStatus == SubmitStatus.submitting;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: hasMember && !isSubmitting
                            ? _openRatingDialog
                            : null,
                        child: const Text('평점 남기기'),
                      ),
                      if (!hasMember)
                        const Text(
                          '먼저 학습용 회원가입을 완료해 주세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
