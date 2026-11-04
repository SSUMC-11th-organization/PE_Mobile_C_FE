// 평점 기록 + 그 movieId로 조회한 TMDB 영화를 한 묶음으로 표시하기 위한 모델
import 'rating_dto.dart';
import 'tmdb_movie_dto.dart';

class RatingWithMovie {
  const RatingWithMovie({required this.rating, this.movie});

  final RatingDto rating;
  final TmdbMovieDto? movie; // TMDB에서 찾지 못했으면 null입니다.
}
