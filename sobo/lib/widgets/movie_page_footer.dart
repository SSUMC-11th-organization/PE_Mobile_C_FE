import 'package:flutter/material.dart';

import '../view_models/paged_movies_view_model.dart';

class MoviePageFooter extends StatelessWidget {
  const MoviePageFooter({super.key, required this.viewModel});

  final PagedMoviesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (viewModel.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(viewModel.loadMoreError!),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: viewModel.loadNextPage,
              child: const Text('같은 페이지 다시 시도'),
            ),
          ],
        ),
      );
    }
    if (!viewModel.hasMore) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text('마지막 페이지입니다.')),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: OutlinedButton(
          onPressed: viewModel.loadNextPage,
          child: const Text('더 보기'),
        ),
      ),
    );
  }
}
