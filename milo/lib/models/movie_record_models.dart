import 'package:movielog/data/models/favorite_response_dto.dart';
import 'package:movielog/data/models/rating_dto.dart';

class CreateMovieRecordRequest {
  const CreateMovieRecordRequest({
    required this.movieId,
    required this.score,
    this.comment,
    required this.addToFavorites,
  });

  final int movieId;
  final int score; // 1~5 정수
  final String? comment;
  final bool addToFavorites; // 필수 boolean

  Map<String, dynamic> toJson() => {
    'movieId': movieId,
    'score': score,
    if (comment != null && comment!.trim().isNotEmpty)
      'comment': comment!.trim(),
    'addToFavorites': addToFavorites,
  };
}

class MovieRecordResponseDto {
  const MovieRecordResponseDto({required this.rating, this.favorite});

  final RatingDto rating;
  final FavoriteResponseDto? favorite; // addToFavorites=false이면 null이 정상입니다.

  factory MovieRecordResponseDto.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException(
        'movie-records result must be a JSON object.',
      );
    }
    final favoriteJson = json['favorite'];
    return MovieRecordResponseDto(
      rating: RatingDto.fromJson(json['rating'] as Map<String, dynamic>),
      favorite: favoriteJson == null
          ? null
          : FavoriteResponseDto.fromJson(favoriteJson),
    );
  }
}
