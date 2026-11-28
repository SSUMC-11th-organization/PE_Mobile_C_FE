import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/load_phase.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/paged_movies_view_model.dart';
import '../widgets/common/common_app_bar.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_page_footer.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<MovieListViewModel>().loadGenres();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '영화',
        actions: [
          IconButton(
            tooltip: '영화 검색',
            onPressed: () => context.push('/movies/search'),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Consumer2<MovieListViewModel, PagedMoviesViewModel>(
        builder: (context, genreModel, pageModel, _) {
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('전체'),
                      selected: genreModel.selectedGenreId == null,
                      onSelected: (_) {
                        genreModel.selectGenre(null);
                        pageModel.loadInitial();
                      },
                    ),
                    for (final genre in genreModel.genres)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(genre.name),
                          selected: genreModel.selectedGenreId == genre.id,
                          onSelected: (selected) {
                            final id = selected ? genre.id : null;
                            genreModel.selectGenre(id);
                            pageModel.loadInitial(genreId: id);
                          },
                        ),
                      ),
                    if (genreModel.genreError != null)
                      TextButton(
                        onPressed: () => genreModel.loadGenres(force: true),
                        child: const Text('장르 다시 불러오기'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _buildMovies(pageModel, genreModel.selectedGenreId),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMovies(PagedMoviesViewModel viewModel, int? genreId) {
    if (viewModel.phase == LoadPhase.idle ||
        viewModel.phase == LoadPhase.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.phase == LoadPhase.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(viewModel.errorMessage ?? '영화 목록을 불러오지 못했습니다.'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => viewModel.loadInitial(genreId: genreId),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    if (viewModel.phase == LoadPhase.empty) {
      return const Center(child: Text('영화가 없습니다.'));
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.loadInitial(genreId: genreId),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid.builder(
              itemCount: viewModel.movies.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.6,
              ),
              itemBuilder: (context, index) =>
                  MovieCard(movie: viewModel.movies[index]),
            ),
          ),
          SliverToBoxAdapter(child: MoviePageFooter(viewModel: viewModel)),
        ],
      ),
    );
  }
}
