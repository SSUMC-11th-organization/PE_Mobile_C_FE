import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';

/// 영화 상세 응답. 목록용 TmdbMovieDto에 런타임·장르 이름·투표 수를 더한 타입입니다.
class TmdbMovieDetailDto extends TmdbMovieDto {
  const TmdbMovieDetailDto({
    required super.id,
    required super.title,
    required super.overview,
    required super.posterPath,
    required super.backdropPath,
    required super.releaseDate,
    required super.genreIds,
    required super.voteAverage,
    required super.popularity,
    required this.runtime,
    required this.genres,
    required this.voteCount,
  });

  final int? runtime;
  final List<TmdbGenreDto> genres;
  final int voteCount;

  String get year {
    final date = releaseDate;
    if (date == null || date.length < 4) return '-';
    return date.substring(0, 4);
  }

  factory TmdbMovieDetailDto.fromJson(Map<String, dynamic> json) {
    final genres = (json['genres'] as List<dynamic>? ?? const [])
        .map((item) => TmdbGenreDto.fromJson(item as Map<String, dynamic>))
        .toList();

    return TmdbMovieDetailDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '제목 없음',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String?,
      genreIds: genres.map((genre) => genre.id).toList(),
      voteAverage: (json['vote_average'] as num? ?? 0).toDouble(),
      popularity: (json['popularity'] as num? ?? 0).toDouble(),
      runtime: (json['runtime'] as num?)?.toInt(),
      genres: genres,
      voteCount: (json['vote_count'] as num? ?? 0).toInt(),
    );
  }
}
