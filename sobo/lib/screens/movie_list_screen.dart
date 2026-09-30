import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../widgets/movie/genre_filter_sheet.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, required this.selectedGenres});

  final List<String> selectedGenres;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  Future<void> _openGenreFilter(List<String> genres) async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return GenreFilterSheet(
          genres: genres,
          selectedGenres: widget.selectedGenres,
        );
      },
    );

    if (!mounted || result == null) return;

    final uri = Uri(
      path: '/movies',
      queryParameters: result.isEmpty ? null : {'genre': result},
    );

    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final genres = movies.map((movie) => movie.genre).toSet().toList();

    final filteredMovies = widget.selectedGenres.isEmpty
        ? movies
        : movies
              .where((movie) => widget.selectedGenres.contains(movie.genre))
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('영화'),
        actions: [
          IconButton(
            onPressed: () => _openGenreFilter(genres),
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: '장르 필터',
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredMovies.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.6,
        ),
        itemBuilder: (context, index) {
          final movie = filteredMovies[index];

          return GestureDetector(
            onTap: () => context.push('/movies/${movie.id}'),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(
                      movie.posterAsset,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Text(
                          movie.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('${movie.year} · ${movie.genre}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
