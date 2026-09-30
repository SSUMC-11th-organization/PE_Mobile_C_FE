// ignore_for_file: avoid_print

class Movie {
  final String title;
  final int year;
  final String genre;
  final double rating;

  const Movie({
    required this.title,
    required this.year,
    required this.genre,
    required this.rating,
  });
}

String displayNickname(String? nickname) {
  return nickname ?? "익명";
}

void main() {
  final movies = <Movie>[
    const Movie(title: "인터스텔라", year: 2014, genre: "SF", rating: 4.8),
    const Movie(title: "기생충", year: 2019, genre: "Drama", rating: 4.7),
    const Movie(title: "올드보이", year: 2003, genre: "Thriller", rating: 4.3),
  ];

  for (final movie in movies) {
    print(movie.title);
  }

  final titles = movies.map((movie) => movie.genre).toList();
  print(titles);
}
