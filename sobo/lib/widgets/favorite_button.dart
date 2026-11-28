import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/favorite_detail_view_model.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key});

  Future<void> _toggle(
    BuildContext context,
    FavoriteDetailViewModel viewModel,
  ) async {
    final success = await viewModel.toggle();
    if (!context.mounted) return;

    final message = success
        ? viewModel.isFavorite
              ? '즐겨찾기에 추가했어요.'
              : '즐겨찾기를 해제했어요.'
        : viewModel.errorMessage;
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteDetailViewModel>(
      builder: (context, viewModel, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: viewModel.isLoading || viewModel.isSaving
                  ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      tooltip: viewModel.isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
                      onPressed: viewModel.hasLoadedStatus
                          ? () => _toggle(context, viewModel)
                          : null,
                      icon: Icon(
                        viewModel.isFavorite
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
            ),
            const Text('즐겨찾기'),
            if (!viewModel.hasLoadedStatus &&
                !viewModel.isLoading &&
                viewModel.errorMessage != null)
              SizedBox(
                width: 112,
                child: Text(
                  viewModel.errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (!viewModel.hasLoadedStatus && !viewModel.isLoading)
              IconButton(
                tooltip: '즐겨찾기 여부 다시 조회',
                onPressed: viewModel.load,
                icon: const Icon(Icons.refresh),
              ),
          ],
        );
      },
    );
  }
}
