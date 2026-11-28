class FavoriteCheckDto {
  const FavoriteCheckDto({required this.movieId, required this.isFavorite});

  final int movieId;
  final bool isFavorite;

  factory FavoriteCheckDto.fromJson(Object? json, {required int movieId}) {
    if (json is! Map<String, dynamic> || json['isFavorite'] is! bool) {
      throw const FormatException('즐겨찾기 여부 응답 형식이 올바르지 않습니다.');
    }
    return FavoriteCheckDto(
      movieId: movieId,
      isFavorite: json['isFavorite'] as bool,
    );
  }
}
