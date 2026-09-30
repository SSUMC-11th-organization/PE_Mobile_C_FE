class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.posterAsset,
    required this.averageRating,
  });

  final int id;
  final String title;
  final String genre;
  final int year;
  final String posterAsset;
  final double averageRating;
}

const movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2023,
    posterAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
    averageRating: 4.5,
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    averageRating: 4.0,
  ),
  Movie(
    id: 3,
    title: '속삭이는 숲',
    genre: '판타지',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
    averageRating: 4.7,
  ),
  Movie(
    id: 4,
    title: '미션: 임프로버블',
    genre: '액션',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_abyss_walker.jpg',
    averageRating: 4.2,
  ),
  Movie(
    id: 5,
    title: '네 번째 오후',
    genre: '로맨스',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_fourth_afternoon.jpg',
    averageRating: 4.6,
  ),
  Movie(
    id: 6,
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
    averageRating: 4.1,
  ),
];

Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}
