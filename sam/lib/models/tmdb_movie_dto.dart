// TMDB 영화 목록·장르 응답 DTO
import 'movie.dart';

const _posterBaseUrl = 'https://image.tmdb.org/t/p/w500';

// TMDB 영화 장르 id → 한글 이름 (https://developer.themoviedb.org/reference/genre-movie-list)
const _genreNames = {
  28: '액션',
  12: '모험',
  16: '애니메이션',
  35: '코미디',
  80: '범죄',
  99: '다큐멘터리',
  18: '드라마',
  10751: '가족',
  14: '판타지',
  36: '역사',
  27: '공포',
  10402: '음악',
  9648: '미스터리',
  10749: '로맨스',
  878: 'SF',
  10770: 'TV 영화',
  53: '스릴러',
  10752: '전쟁',
  37: '서부',
};

class TmdbMoviePageDto {
  const TmdbMoviePageDto({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  final int page;
  final List<TmdbMovieDto> results;
  final int totalPages;
  final int totalResults;

  factory TmdbMoviePageDto.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? const [];

    return TmdbMoviePageDto(
      page: (json['page'] as num).toInt(),
      results: rawResults
          .map((item) => TmdbMovieDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalPages: (json['total_pages'] as num).toInt(),
      totalResults: (json['total_results'] as num).toInt(),
    );
  }
}

class TmdbMovieDto {
  const TmdbMovieDto({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.genreIds,
    required this.voteAverage,
    required this.popularity,
  });

  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  // 'YYYY-MM-DD' 형식, 개봉일 미정이면 null 또는 빈 문자열
  final String? releaseDate;
  final List<int> genreIds;
  final double voteAverage;
  final double popularity;

  factory TmdbMovieDto.fromJson(Map<String, dynamic> json) {
    return TmdbMovieDto(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '제목 없음',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String?,
      genreIds: (json['genre_ids'] as List<dynamic>? ?? const [])
          .map((value) => (value as num).toInt())
          .toList(),
      voteAverage: (json['vote_average'] as num? ?? 0).toDouble(),
      popularity: (json['popularity'] as num? ?? 0).toDouble(),
    );
  }

  Movie toMovie() {
    final path = posterPath;

    return Movie(
      id: id,
      title: title,
      genre: genreIds.isEmpty ? '기타' : _genreNames[genreIds.first] ?? '기타',
      year: int.tryParse(releaseDate?.split('-').first ?? ''),
      posterUrl: path == null || path.isEmpty ? null : '$_posterBaseUrl$path',
    );
  }
}

class TmdbGenreDto {
  const TmdbGenreDto({required this.id, required this.name});
  final int id;
  final String name;

  factory TmdbGenreDto.fromJson(Map<String, dynamic> json) {
    return TmdbGenreDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );
  }
}
