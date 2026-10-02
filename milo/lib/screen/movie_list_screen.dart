import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/mock_movie.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/widgets/movie/genre_filter_sheet.dart';
import 'package:movielog/widgets/movie/movie_grid_card.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, this.initialGenres = const []});

  final List<String> initialGenres;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const allGenres = ['드라마', 'SF', '애니메이션', '스릴러', '로맨스', '액션', '다큐멘터리'];

  late Set<String> appliedGenres = widget.initialGenres.toSet();

  List<Movie> get filteredMovies {
    if (appliedGenres.isEmpty) return movies;
    return movies
        .where((movie) => appliedGenres.contains(movie.genre))
        .toList();
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => GenreFilterSheet(
        allGenres: allGenres,
        initialSelected: appliedGenres,
      ),
    );

    if (result == null) return;
    if (!mounted) return;

    setState(() => appliedGenres = result);

    final location = result.isEmpty
        ? '/movies'
        : Uri(
            path: '/movies',
            queryParameters: {'genre': result.join(',')},
          ).toString();

    context.go(location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          '영화',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6750A4),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: AppColors.onSurfaceVariant),
          ),
          IconButton(
            onPressed: _openFilterSheet,
            icon: Icon(
              Icons.filter_list,
              color: appliedGenres.isEmpty
                  ? AppColors.onSurfaceVariant
                  : AppColors.primary,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: GridView.builder(
          itemCount: filteredMovies.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 24,
            childAspectRatio: 171 / 316.5,
          ),
          itemBuilder: (context, index) {
            return MovieGridCard(movie: filteredMovies[index]);
          },
        ),
      ),
    );
  }
}
