import 'package:flutter/material.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/models/rating_with_movie.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/loading_overlay.dart';
import 'package:movielog/widgets/movie_card.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:provider/provider.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 선택 삭제 중일 때만 바깥이 다시 그려지도록 select로 구독
    final isDeleting = context.select<MyRatingsViewModel, bool>(
      (vm) => vm.isDeletingSelected,
    );

    return PopScope(
      // 삭제 요청이 도는 동안 뒤로가기로 화면이 닫히지 않게 막습니다.
      canPop: !isDeleting,
      child: LoadingOverlay(
        isLoading: isDeleting,
        child: Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            centerTitle: true,
            title: const Text('내가 등록한 평점'),
          ),
          body: const SafeArea(child: _MyRatingsListView()),
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
        return switch (viewModel.status) {
          MyRatingsLoadStatus.idle || MyRatingsLoadStatus.loading =>
            const Center(child: CircularProgressIndicator()),
          MyRatingsLoadStatus.empty => const Center(
            child: Text('아직 등록한 평점이 없어요.'),
          ),
          MyRatingsLoadStatus.error => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(viewModel.message ?? '평점을 불러오지 못했어요.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: viewModel.load,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
          MyRatingsLoadStatus.success => Column(
            children: [
              if (viewModel.refreshWarning != null)
                _Banner(
                  text: viewModel.refreshWarning!,
                  action: TextButton(
                    onPressed: viewModel.load,
                    child: const Text('다시 불러오기'),
                  ),
                ),
              if (viewModel.message != null) _Banner(text: viewModel.message!),
              _SelectionHeader(
                isSelectionMode: viewModel.isSelectionMode,
                selectedCount: viewModel.selectedRatingIds.length,
                onEdit: viewModel.startSelection,
                onCancel: viewModel.cancelSelection,
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.ratings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final entry = viewModel.ratings[index];
                    final ratingId = entry.rating.ratingId;
                    return _RatingTile(
                      entry: entry,
                      selectionMode: viewModel.isSelectionMode,
                      selected: viewModel.selectedRatingIds.contains(ratingId),
                      onSelectedChanged: () =>
                          viewModel.toggleSelected(ratingId),
                    );
                  },
                ),
              ),
              if (viewModel.isSelectionMode)
                _SelectedActionBar(
                  count: viewModel.selectedRatingIds.length,
                  onDelete: viewModel.selectedRatingIds.isEmpty
                      ? null
                      : () => _onDeleteSelectedPressed(context),
                ),
            ],
          ),
        };
      },
    );
  }

  Future<void> _onDeleteSelectedPressed(BuildContext context) async {
    final viewModel = context.read<MyRatingsViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('선택한 평점을 삭제할까요?'),
        content: const Text('삭제한 평점은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    // 삭제 요청은 Dialog가 닫힌 뒤 화면에서 시작

    if (confirmed != true || !context.mounted) return;

    await viewModel.deleteSelectedRatings();

    final failed = viewModel.selectedRatingIds.length;
    if (failed > 0) {
      // 성공한 항목은 목록에서 사라짐
      messenger.showSnackBar(
        SnackBar(content: Text('$failed개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.')),
      );
    } else {
      viewModel.cancelSelection();
    }
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.primaryContainer,
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onEdit,
    required this.onCancel,
  });

  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: 'Manrope',
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 12, 0),
      child: Row(
        children: [
          if (isSelectionMode) Text('$selectedCount개 선택됨', style: style),
          const Spacer(),
          TextButton(
            onPressed: isSelectionMode ? onCancel : onEdit,
            child: Text(isSelectionMode ? '취소' : '편집', style: style),
          ),
        ],
      ),
    );
  }
}

class _SelectedActionBar extends StatelessWidget {
  const _SelectedActionBar({required this.count, required this.onDelete});

  final int count;
  final VoidCallback? onDelete; // 선택이 0개면 null이라 비활성화됩니다.

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: MovieLogButton(
        label: '선택한 $count개 삭제',
        width: double.infinity,
        onPressed: onDelete,
      ),
    );
  }
}

class _TileActionButton extends StatelessWidget {
  const _TileActionButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: SizedBox(
          width: 64,
          height: 36,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingTile extends StatelessWidget {
  const _RatingTile({
    required this.entry,
    required this.selectionMode,
    required this.selected,
    required this.onSelectedChanged,
  });

  final RatingWithMovie entry;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onSelectedChanged;

  @override
  Widget build(BuildContext context) {
    final movie = entry.movie;
    final rating = entry.rating;
    final title = movie?.title ?? '영화 #${rating.movieId}';
    final comment = rating.comment;
    final hasComment = comment != null && comment.isNotEmpty;

    const commentStyle = TextStyle(
      fontFamily: 'Manrope',
      fontSize: 16,
      color: AppColors.onSurfaceVariant,
    );

    final Widget body;
    if (selectionMode) {
      // 선택 모드: 체크박스 + "제목 · 별점 N" + 코멘트
      body = Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (_) => onSelectedChanged(),
            activeColor: AppColors.primary,
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title · 별점 ${rating.score}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                if (hasComment) ...[
                  const SizedBox(height: 8),
                  Text(comment, style: commentStyle),
                ],
              ],
            ),
          ),
        ],
      );
    } else {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            // movie가 null이면 posterPath도 null이라 placeholder가 그려집니다.
            child: TmdbPosterImage(
              posterPath: movie?.posterPath,
              width: 82,
              height: 124,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '별점 ${rating.score} / 5',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                if (hasComment) ...[
                  const SizedBox(height: 8),
                  Text(comment, style: commentStyle),
                ],
                if (movie == null) ...[
                  const SizedBox(height: 8),
                  const Text('포스터 정보 없음', style: commentStyle),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              _TileActionButton(
                label: '수정',
                background: const Color(0xFFEEE9F8),
                foreground: AppColors.primary,
                onPressed: () => onEditPressed(context, rating),
              ),
              const SizedBox(height: 8),
              _TileActionButton(
                label: '삭제',
                background: const Color(0xFFFFEFEF),
                foreground: const Color(0xFFB3261E),
                onPressed: () => onDeletePressed(context, rating),
              ),
            ],
          ),
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // 선택 모드에서는 카드 어디를 눌러도 선택이 토글됩니다.
      onTap: selectionMode ? onSelectedChanged : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outline, width: 2),
        ),
        child: body,
      ),
    );
  }

  Future<void> onEditPressed(BuildContext context, RatingDto rating) async {
    // 저장 후 목록이 다시 그려지면 이 타일의 context는 사라질 수 있어서
    // await 전에 필요한 객체를 미리 꺼내 둡니다.
    final viewModel = context.read<MyRatingsViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막습니다.
      builder: (_) => RatingDialog(
        initialScore: rating.score,
        initialComment: rating.comment, // null이면 TextField가 빈 칸으로 시작합니다.
        onSubmit: (score, comment) => viewModel.updateRating(
          ratingId: rating.ratingId,
          score: score,
          comment: comment,
        ),
      ),
    );

    if (saved != true) return;
    messenger.showSnackBar(const SnackBar(content: Text('평점을 수정했습니다.')));
  }

  Future<void> onDeletePressed(BuildContext context, RatingDto rating) async {
    final viewModel = context.read<MyRatingsViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteRatingDialog(
        onConfirm: () => viewModel.deleteRating(rating.ratingId),
      ),
    );

    if (confirmed != true) return;
    messenger.showSnackBar(const SnackBar(content: Text('평점을 삭제했습니다.')));
  }
}

class _DeleteRatingDialog extends StatefulWidget {
  const _DeleteRatingDialog({required this.onConfirm});
  final Future<void> Function() onConfirm;

  @override
  State<_DeleteRatingDialog> createState() => _DeleteRatingDialogState();
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
            onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
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
        const SnackBar(content: Text('삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }
}
