import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../data/models/tmdb_movie_dto.dart';
import '../../widgets/movie/ratings/rating_dialog.dart';
import '../../widgets/tmdb_poster_image.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({
    super.key,
    required this.movie,
  });

  final TmdbMovieDto movie;

  @override
  State<MovieDetailScreen> createState() =>
      _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  double? selectedRating;
  bool isFavorite = false;

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite
              ? '즐겨찾기에 추가했어요.'
              : '즐겨찾기를 해제했어요.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openRatingDialog() async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => RatingDialog(
        movieId: widget.movie.id,
        movieTitle: widget.movie.title,
        initialRating: selectedRating ?? 0,
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      selectedRating = result == 0 ? null : result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final releaseDate = movie.releaseDate;

    final releaseText =
    releaseDate == null || releaseDate.isEmpty
        ? '개봉일 미정'
        : releaseDate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('영화 상세'),
      ),
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
                          return const Icon(
                            Icons.star,
                            color: Colors.amber,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${movie.voteAverage.toStringAsFixed(1)} / 10',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '줄거리',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.overview.trim().isEmpty
                        ? '등록된 줄거리가 없습니다.'
                        : movie.overview,
                  ),
                  if (selectedRating != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      '내 별점: '
                          '${selectedRating!.toStringAsFixed(1)} / 5',
                    ),
                  ],
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
                    isFavorite
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                  ),
                  label: const Text('즐겨찾기'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _openRatingDialog,
                  child: const Text('평점 남기기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}