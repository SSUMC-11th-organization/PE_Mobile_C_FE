import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'package:flutter/material.dart';

class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
  });

  final double rating;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 0.5, // 최소 별점
      allowHalfRating: true, // 0.5점 단위 허용
      itemCount: 5,
      itemSize: 40,
      itemBuilder: (context, index) {
        return const Icon(Icons.star, color: Colors.amber);
      },
      onRatingUpdate: onChanged,
    );
  }
}
