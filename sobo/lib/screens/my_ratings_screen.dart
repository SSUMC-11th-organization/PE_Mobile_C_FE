import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../view_models/my_ratings_view_model.dart';
import '../services/rating_api_service.dart';
import '../widgets/movie/ratings/rating_dialog.dart';
import '../widgets/movielog_button.dart';
import '../widgets/loading_overlay.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyRatingsViewModel>(
      builder: (context, viewModel, child) => PopScope(
        canPop: !viewModel.isDeletingSelected,
        child: LoadingOverlay(
          isLoading: viewModel.isDeletingSelected,
          child: Scaffold(
            appBar: AppBar(
              leading: const BackButton(),
              title: const Text('내가 등록한 평점'),
              centerTitle: true,
              actions: [
                TextButton(
                  onPressed: viewModel.selectedRatingIds.isEmpty || viewModel.isDeletingSelected
                      ? null
                      : () => onDeleteSelectedPressed(context),
                  child: Text('선택 삭제 (${viewModel.selectedRatingIds.length})'),
                ),
              ],
            ),
            body: const _MyRatingsListView(),
          ),
        ),
      ),
    );
  }
}

class _MyRatingsListView extends StatelessWidget {
  const _MyRatingsListView();

  @override
  Widget build(BuildContext context) {
    return Consumer<MyRatingsViewModel>(
      builder: (context, viewModel, child) {
          switch (viewModel.status) {
            case MyRatingsLoadStatus.idle:
            case MyRatingsLoadStatus.loading:
              return const Center(child: CircularProgressIndicator());

            case MyRatingsLoadStatus.empty:
              return const Center(child: Text('등록된 평점이 없습니다.'));

            case MyRatingsLoadStatus.error:
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        viewModel.refreshWarning ??
                            viewModel.message ??
                            '평점을 불러오지 못했습니다.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => viewModel.load(),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              );

            case MyRatingsLoadStatus.success:
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('학습용 회원 ${viewModel.memberId}의 평점입니다.'),
                  const SizedBox(height: 16),
                  if (viewModel.message != null) ...[
                    Text(viewModel.message!),
                    const SizedBox(height: 16),
                  ],
                  for (final entry in viewModel.ratings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _RatingCard(entry: entry),
                    ),
                ],
              );
          }
      },
    );
  }
}


class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.entry});

  final RatingWithMovie entry;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;
    final posterPath = movie?.posterPath;
    final comment = rating.comment;
    final date = rating.createdAt.toLocal();
    final formattedDate =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';

    Widget placeholder() {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined, size: 32),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFDCD5E5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: context.watch<MyRatingsViewModel>().selectedRatingIds.contains(rating.ratingId),
              onChanged: (_) => context.read<MyRatingsViewModel>().toggleRatingSelection(rating.ratingId),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 120,
                child: posterPath == null || posterPath.isEmpty
                    ? placeholder()
                    : Image.network(
                        'https://image.tmdb.org/t/p/w342$posterPath',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return placeholder();
                        },
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie?.title ?? '영화 #${rating.movieId}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '별점 ${rating.score} / 5',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (comment != null && comment.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(comment),
                  ],
                  const SizedBox(height: 12),
                  Text(formattedDate, style: Theme.of(context).textTheme.bodySmall),

                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => onEditPressed(context, rating),
                  child: const Text('수정'),
                ),
                TextButton(
                  onPressed: () => onDeletePressed(context, rating),
                  child: const Text('삭제'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> onEditPressed(BuildContext context, RatingDto rating) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => RatingDialog(
      initialScore: rating.score,
      initialComment: rating.comment,
      onSubmit: (score, comment) => context.read<MyRatingsViewModel>().updateRating(
        ratingId: rating.ratingId,
        score: score,
        comment: comment,
      ),
    ),
  );
  if (!context.mounted || saved != true) return;
}

Future<void> onDeletePressed(
    BuildContext context,
    RatingDto rating,
    ) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DeleteRatingDialog(
      onConfirm: () =>
          context.read<MyRatingsViewModel>().deleteRating(rating.ratingId),
    ),
  );
  // confirmed는 실제로 삭제까지 마쳤을 때만 true입니다.
  if (!context.mounted || confirmed != true) return;
}

class _DeleteRatingDialog extends StatefulWidget {
  const _DeleteRatingDialog({required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  State<_DeleteRatingDialog> createState() =>
      _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<_DeleteRatingDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        title: const Text('평점을 삭제할까요?'),
        content: const Text('삭제한 평점은 복구할 수 없습니다.'),
        actions: [
          MovieLogButton(
            label: '취소',
            onPressed: _isDeleting
                ? null
                : () => Navigator.pop(context, false),
          ),
          MovieLogButton(
            label: '삭제',
            isLoading: _isDeleting,
            onPressed: _isDeleting ? null : _onConfirm,
          ),
        ],
      ),
    );
  }

  Future<void> _onConfirm() async {
    setState(() => _isDeleting = true);

    try {
      await widget.onConfirm();

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is DioException
              ? writeErrorMessage(error)
              : '삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.'),
        ),
      );
    }
  }
}


Future<void> onDeleteSelectedPressed(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('선택한 평점을 삭제할까요?'),
      content: const Text('삭제한 평점은 복구할 수 없습니다.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await context.read<MyRatingsViewModel>().deleteSelectedRatings();
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('삭제 결과를 확인하지 못했습니다. 목록을 다시 조회해 주세요.')),
    );
  }
}
