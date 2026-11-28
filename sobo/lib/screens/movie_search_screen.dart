import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import '../widgets/common/common_app_bar.dart';
import '../widgets/movie_card.dart';
import '../widgets/movie_page_footer.dart';

class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key, required this.onOpenMovie});

  final Future<void> Function(TmdbMovieDto movie) onOpenMovie;

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final _controller = TextEditingController();
  String _submittedQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final query = _controller.text.trim();
    setState(() => _submittedQuery = query);
    context.read<PagedMoviesViewModel>().loadInitial(
      query: query,
      searchMode: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '영화 검색', centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: '영화 제목을 입력하세요',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: '검색',
                  onPressed: _search,
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: Consumer<PagedMoviesViewModel>(
              builder: (context, viewModel, _) {
                if (viewModel.phase == LoadPhase.idle) {
                  return const Center(child: Text('검색어를 입력해 주세요.'));
                }
                if (viewModel.phase == LoadPhase.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (viewModel.phase == LoadPhase.error) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(viewModel.errorMessage ?? '검색에 실패했습니다.'),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => viewModel.loadInitial(
                            query: _submittedQuery,
                            searchMode: true,
                          ),
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  );
                }
                if (viewModel.phase == LoadPhase.empty) {
                  return Center(child: Text('“$_submittedQuery” 검색 결과가 없습니다.'));
                }

                return RefreshIndicator(
                  onRefresh: () => viewModel.loadInitial(
                    query: _submittedQuery,
                    searchMode: true,
                  ),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverGrid.builder(
                          itemCount: viewModel.movies.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.6,
                              ),
                          itemBuilder: (context, index) => MovieCard(
                            movie: viewModel.movies[index],
                            onOpen: widget.onOpenMovie,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: MoviePageFooter(viewModel: viewModel),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
