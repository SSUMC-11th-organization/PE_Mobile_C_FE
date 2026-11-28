import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/load_phase.dart';
import '../widgets/common/common_app_bar.dart';
import '../widgets/movie_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.onOpenMovie});

  final Future<void> Function(TmdbMovieDto movie) onOpenMovie;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoritesViewModel>().refresh();
    });
  }

  Future<void> _openMovie(TmdbMovieDto movie) async {
    await widget.onOpenMovie(movie);
    if (!mounted) return;
    await context.read<FavoritesViewModel>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '내 즐겨찾기', centerTitle: true),
      body: Consumer<FavoritesViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.phase == LoadPhase.idle ||
              viewModel.phase == LoadPhase.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.phase == LoadPhase.empty) {
            return const Center(child: Text('아직 즐겨찾기한 영화가 없습니다.'));
          }
          if (viewModel.phase == LoadPhase.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(viewModel.errorMessage ?? '조회 오류가 발생했습니다.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: viewModel.refresh,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.6,
              ),
              itemBuilder: (context, index) {
                final item = viewModel.items[index];
                final movie = item.movie;
                if (movie == null) {
                  return Card(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image_outlined, size: 40),
                            const SizedBox(height: 8),
                            Text('영화 #${item.favorite.movieId}'),
                            Text(
                              item.errorMessage ?? '영화 정보가 없습니다.',
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed:
                                  viewModel.loadingMovieIds.contains(
                                    item.favorite.movieId,
                                  )
                                  ? null
                                  : () => viewModel.retryMovie(
                                      item.favorite.movieId,
                                    ),
                              child:
                                  viewModel.loadingMovieIds.contains(
                                    item.favorite.movieId,
                                  )
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('정보 다시 조회'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return MovieCard(movie: movie, onOpen: _openMovie);
              },
            ),
          );
        },
      ),
    );
  }
}
