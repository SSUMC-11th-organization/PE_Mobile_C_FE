import 'package:flutter/material.dart';

import '../../models/movie.dart';

class MoviePoster extends StatelessWidget {
  const MoviePoster({super.key, required this.movie, this.borderRadius = 16});

  final Movie movie;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        movie.posterAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _Fallback(movie: movie),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [movie.posterColor, Colors.black87],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            movie.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
