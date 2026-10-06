import 'package:flutter/material.dart';

class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.year,
    required this.genres,
    required this.runtime,
    required this.rating,
    required this.ratingCount,
    required this.synopsis,
    required this.posterColor,
  });

  final String id;
  final String title;
  final int year;
  final List<String> genres;
  final int runtime;
  final double rating;
  final int ratingCount;
  final String synopsis;
  final Color posterColor;

  String get posterAsset => 'assets/posters/$id.png';

  String get mainGenre => genres.first;

  String get yearAndGenre => '$year · $mainGenre';

  String get detailMeta => '$year • ${genres.join('/')} • $runtime분';
}
