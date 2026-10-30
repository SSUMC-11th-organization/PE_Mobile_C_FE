import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../data/mock_movies.dart';
import '../../widgets/movie/ratings/rating_dialog.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final String movieId;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
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
        content: Text(isFavorite ? '즐겨찾기에 추가했어요.' : '즐겨찾기를 해제했어요.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openRatingDialog() async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => RatingDialog(initialRating: selectedRating ?? 0),
    );

    if (!mounted || result == null) return;

    setState(() {
      selectedRating = result == 0 ? null : result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(widget.movieId);
    final movie = findMovieById(id);

    if (movie == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('영화 상세')),
        body: const Center(child: Text('영화를 찾을 수 없습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('영화 상세')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              movie.posterAsset,
              width: double.infinity,
              height: 380,
              fit: BoxFit.cover,
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
                  Text('${movie.year} · ${movie.genre}'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: movie.averageRating,
                        itemCount: 5,
                        itemSize: 24,
                        itemBuilder: (context, index) =>
                            const Icon(Icons.star, color: Colors.amber),
                      ),
                      const SizedBox(width: 8),
                      Text(movie.averageRating.toStringAsFixed(1)),
                    ],
                  ),
                  if (selectedRating != null) ...[
                    const SizedBox(height: 16),
                    Text('내 별점: ${selectedRating!.toStringAsFixed(1)}'),
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
                    isFavorite ? Icons.bookmark : Icons.bookmark_border,
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
