// 영화 모델
class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    this.year,
    this.posterAsset,
    this.posterUrl,
  });

  final int id;
  final String title;
  final String genre;
  // TMDB 응답에 개봉일이 없으면 null
  final int? year;
  final String? posterAsset;
  final String? posterUrl;
}
