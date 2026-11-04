import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../view_models/movie_list_view_model.dart';
import '../../widgets/common/common_app_bar.dart';
import '../../widgets/movie/cards/movie_grid.dart';
import '../../widgets/movie/states/movie_list_empty.dart';
import '../../widgets/movie/states/movie_list_error.dart';
import '../../widgets/movie/states/movie_list_loading.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '영화'),
      body: Consumer<MovieListViewModel>(
        builder: (context, viewModel, child) {
          final isLoading =
              viewModel.status == MovieListLoadStatus.loading;

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
                      selected: viewModel.selectedGenreId == null,
                      onSelected: isLoading
                          ? null
                          : (_) {
                        context
                            .read<MovieListViewModel>()
                            .selectGenre(null);
                      },
                    ),
                    for (final genre in viewModel.genres)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(genre.name),
                          selected:
                          viewModel.selectedGenreId == genre.id,
                          onSelected: isLoading
                              ? null
                              : (selected) {
                            context
                                .read<MovieListViewModel>()
                                .selectGenre(
                              selected ? genre.id : null,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () {
                    return context
                        .read<MovieListViewModel>()
                        .loadInitial();
                  },
                  child: _buildContent(context, viewModel),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      MovieListViewModel viewModel,
      ) {
    switch (viewModel.status) {
      case MovieListLoadStatus.idle:
      case MovieListLoadStatus.loading:
        return const MovieListLoading();

      case MovieListLoadStatus.error:
        return _scrollableStatus(
          MovieListError(
            onRetry: () {
              context.read<MovieListViewModel>().loadInitial();
            },
          ),
        );

      case MovieListLoadStatus.empty:
        return _scrollableStatus(
          const MovieListEmpty(),
        );

      case MovieListLoadStatus.success:
        return MovieGrid(
          movies: viewModel.movies,
        );
    }
  }

  Widget _scrollableStatus(Widget child) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: child,
        ),
      ],
    );
  }
}