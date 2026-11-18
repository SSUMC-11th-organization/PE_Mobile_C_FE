import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../models/favorite_list_item.dart';
import '../theme/app_colors.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/load_phase.dart';
import '../widgets/movielog_button.dart';

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
      if (mounted) {
        context.read<FavoritesViewModel>().refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    appBar: AppBar(
      backgroundColor: AppColors.surface,
      title: const Text('내 즐겨찾기'),
      centerTitle: true,
    ),
    body: Consumer<FavoritesViewModel>(
      builder: (context, vm, _) {
        if (vm.phase == LoadPhase.idle || vm.phase == LoadPhase.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.phase == LoadPhase.empty) {
          return const _EmptyView();
        }

        if (vm.phase == LoadPhase.error) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vm.errorMessage ?? '즐겨찾기를 불러오지 못했습니다.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                MovieLogButton(
                  width: 220,
                  label: '다시 시도',
                  onPressed: vm.refresh,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: vm.refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: vm.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = vm.items[index];
              return _FavoriteCard(
                item: item,
                onTap: item.movie == null
                    ? null
                    : () async {
                        await widget.onOpenMovie(item.movie!);
                        if (!mounted) return;
                        // ViewModel도 같은 현재 세션인지 다시 확인합니다.
                        await vm.refresh();
                      },
                onRetry: vm.refresh,
              );
            },
          ),
        );
      },
    ),
  );
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.item, this.onTap, required this.onRetry});

  final FavoriteListItem item;
  final VoidCallback? onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final movie = item.movie;
    final path = movie?.posterPath;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.inputBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 포스터: 정보가 없거나 실패하면 연보라 빈 칸을 보여 줍니다.
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 78,
                  height: 116,
                  child: path == null
                      ? const ColoredBox(color: AppColors.navIndicator)
                      : Image.network(
                          'https://image.tmdb.org/t/p/w185$path',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(color: AppColors.navIndicator),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie?.title ?? 'TMDB #${item.favorite.movieId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'TMDB 영화 ID로 연결합니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '즐겨찾기한 영화',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    if (movie == null) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: onRetry,
                        child: const Text(
                          '정보 다시 불러오기',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_border, size: 32, color: AppColors.primary),
          SizedBox(height: 24),
          Text(
            '아직 즐겨찾기한 영화가 없습니다.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '영화 상세에서 북마크를 눌러보세요.',
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
