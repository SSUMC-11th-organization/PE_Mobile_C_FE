import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'movie_rating_input.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    required this.movieId,
    required this.movieTitle,
    this.initialRating = 0,
  });

  final int movieId;
  final String movieTitle;
  final double initialRating;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late double rating;

  @override
  void initState() {
    super.initState();
    rating = widget.initialRating;

    if (kDebugMode) {
      debugPrint(
        '[평점 Dialog] movieId=${widget.movieId}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.movieTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('영화는 어떠셨나요?'),
            const SizedBox(height: 24),
            MovieRatingInput(
              rating: rating,
              onChanged: (value) {
                setState(() {
                  rating = value;
                });
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      rating = 0;
                    });
                  },
                  child: const Text('초기화'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (kDebugMode) {
                      debugPrint(
                        '[평점 선택] '
                            'movieId=${widget.movieId}, '
                            'rating=$rating',
                      );
                    }

                    Navigator.pop(context, rating);
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}