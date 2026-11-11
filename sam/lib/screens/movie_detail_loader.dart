// 영화 상세 화면의 시작점: 넘겨받은 영화가 없으면 TMDB에서 한 번 조회합니다.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/movie.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/movie_detail_view_model.dart';
import 'movie_detail_screen.dart';

class MovieDetailLoader extends StatefulWidget {
  const MovieDetailLoader({
    super.key,
    required this.movieId,
    this.initialMovie,
  });
  final int movieId;
  final Movie? initialMovie;

  @override
  State<MovieDetailLoader> createState() => _MovieDetailLoaderState();
}

class _MovieDetailLoaderState extends State<MovieDetailLoader> {
  late final Future<Movie> _movieFuture;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMovie;
    _movieFuture = initial != null
        ? Future.value(initial)
        : context
              .read<TmdbMovieService>()
              .fetchMovieDetail(widget.movieId)
              .then((dto) => dto.toMovie());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Movie>(
      future: _movieFuture, // build마다 새 Future를 만들지 않습니다.
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text('영화를 불러오지 못했습니다.')));
        }
        return ChangeNotifierProvider<MovieDetailViewModel>(
          create: (context) => MovieDetailViewModel(
            context.read<RatingApiService>(),
            context.read<LearningMemberSession>().memberId,
            snapshot.data!,
          ),
          child: const MovieDetailScreen(),
        );
      },
    );
  }
}
