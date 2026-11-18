import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';
import 'package:movielog/widgets/movie_card.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, this.initialGenres = const []});

  final List<String> initialGenres;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  late final PagedMoviesViewModel _viewModel;
  final ScrollController _scrollController = ScrollController();
  static const double _loadMoreThreshold = 300; // 남은 스크롤 거리(px)
  bool _isDialogShowing = false;

  List<TmdbGenreDto> _genres = const [];
  List<int> _selectedGenreIds = [];
  List<int> _lastSuccessGenreIds = [];

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<PagedMoviesViewModel>();
    _viewModel.addListener(_onViewModelChanged);
    _scrollController.addListener(_maybeLoadMore);
    _loadGenres();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _scrollController.removeListener(_maybeLoadMore);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await context.read<TmdbMovieService>().fetchGenres();
      if (!mounted) return;
      setState(() => _genres = genres);
    } catch (_) {
      // 장르 조회 실패 시 필터 버튼을 눌렀을 때 다시 시도합니다.
    }
  }

  void _maybeLoadMore() {
    if (!mounted || !_scrollController.hasClients) return;
    if (_viewModel.loadMoreError != null) return; // 실패 뒤에는 자동 재요청하지 않습니다.
    if (_scrollController.position.extentAfter <= _loadMoreThreshold) {
      _viewModel.loadNextPage();
    }
  }

  void _onViewModelChanged() {
    // 목록이 새로 그려진 뒤에도 화면이 덜 찼으면(스크롤이 안 생기는 경우) 이어서 불러옵니다.
    if (_viewModel.phase == LoadPhase.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore());
    }

    // 성공한 조건을 기억해 두었다가, 실패하면 이 조건으로 되돌립니다.
    if (_viewModel.phase == LoadPhase.ready ||
        _viewModel.phase == LoadPhase.empty) {
      _lastSuccessGenreIds = List.of(_selectedGenreIds);
      return;
    }
    // 장르를 바꾼 뒤 첫 조회가 실패한 경우에만 다이얼로그를 띄웁니다.
    // (처음 진입 실패는 화면의 '다시 시도' 버튼이 담당합니다.)
    if (_viewModel.phase != LoadPhase.error || _isDialogShowing) return;
    if (listEquals(_selectedGenreIds, _lastSuccessGenreIds)) return;
    _showRetryDialog();
  }

  Future<void> _showRetryDialog() async {
    _isDialogShowing = true;

    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.replay,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '영화를 불러오지 못했어요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '네트워크 상태를 확인하고\n다시 시도해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  height: 1.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer.withValues(
                          alpha: 0.4,
                        ),
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(52),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('다시 시도'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    _isDialogShowing = false;
    if (!mounted) return;

    if (retry == true) {
      _viewModel.loadInitial(genreIds: _selectedGenreIds);
    } else {
      setState(() => _selectedGenreIds = List.of(_lastSuccessGenreIds));
      _viewModel.loadInitial(genreIds: _selectedGenreIds);
    }
  }

  Future<void> _openGenreSheet() async {
    if (_genres.isEmpty) {
      await _loadGenres();
      if (!mounted) return;
      if (_genres.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('장르를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.')),
        );
        return;
      }
    }

    final result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => GenreFilterSheet(
        genres: _genres,
        initialSelectedIds: _selectedGenreIds,
      ),
    );

    if (result == null || !mounted) return;
    if (listEquals(result, _selectedGenreIds)) return;

    setState(() => _selectedGenreIds = List.of(result));
    await _viewModel.loadInitial(genreIds: _selectedGenreIds);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PagedMoviesViewModel>();
    final isLoading = viewModel.phase == LoadPhase.loading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          '영화',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.55,
            color: Color(0xFF4F378A),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/movies/search'),
            icon: const Icon(Icons.search, color: AppColors.onPrimaryContainer),
          ),
          IconButton(
            onPressed: isLoading ? null : _openGenreSheet,
            icon: Icon(
              Icons.filter_list,
              color: _selectedGenreIds.isEmpty
                  ? AppColors.onSurfaceVariant
                  : AppColors.primary,
            ),
          ),
        ],
      ),
      body: switch (viewModel.phase) {
        LoadPhase.idle || LoadPhase.loading => const MovieListLoading(),
        LoadPhase.error => MovieListError(
          message: viewModel.errorMessage ?? '오류가 발생했습니다.',
          onRetry: () => viewModel.loadInitial(genreIds: _selectedGenreIds),
        ),
        LoadPhase.empty => const MovieListEmpty(),
        LoadPhase.ready => RefreshIndicator(
          onRefresh: () => viewModel.loadInitial(genreIds: _selectedGenreIds),
          child: MovieGrid(
            controller: _scrollController,
            movies: viewModel.movies,
            footer: _MovieListFooter(vm: viewModel),
          ),
        ),
      },
    );
  }
}

class MovieGrid extends StatelessWidget {
  const MovieGrid({
    super.key,
    required this.movies,
    this.footer,
    this.controller,
  });

  final List<TmdbMovieDto> movies;
  final Widget? footer;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 24,
              childAspectRatio: 171 / 316.5,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => MovieCard(movie: movies[index]),
              childCount: movies.length,
            ),
          ),
        ),
        if (footer != null) SliverToBoxAdapter(child: footer),
      ],
    );
  }
}

class _MovieListFooter extends StatelessWidget {
  const _MovieListFooter({required this.vm});

  final PagedMoviesViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (vm.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(vm.loadMoreError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            MovieLogButton(
              width: double.infinity,
              label: '다음 페이지 다시 시도',
              onPressed: vm.loadNextPage, // 같은 page를 다시 요청합니다.
            ),
          ],
        ),
      );
    }

    if (!vm.hasMore) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('모든 영화를 확인했습니다.', textAlign: TextAlign.center),
      );
    }

    return const SizedBox(height: 24);
  }
}

class MovieListLoading extends StatefulWidget {
  const MovieListLoading({super.key});

  @override
  State<StatefulWidget> createState() => _MovieListLoadingState();
}

class _MovieListLoadingState extends State<MovieListLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_controller),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 24,
            childAspectRatio: 171 / 316.5,
          ),
          itemBuilder: (BuildContext context, int index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: double.infinity,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 6),
                Container(height: 12, width: 80, color: Colors.grey.shade300),
              ],
            );
          },
          physics: const NeverScrollableScrollPhysics(),
        ),
      ),
    );
  }
}

class MovieListEmpty extends StatelessWidget {
  const MovieListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('조건에 맞는 영화가 없습니다.'));
  }
}

class MovieListError extends StatelessWidget {
  const MovieListError({
    super.key,
    required this.onRetry,
    this.message = '오류가 발생했습니다.',
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class SortOptionSheet extends StatelessWidget {
  const SortOptionSheet({super.key, required this.selected});

  final MovieSortOption selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in MovieSortOption.values)
            ListTile(
              title: Text(option.label),
              trailing: selected == option ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, option),
            ),
        ],
      ),
    );
  }
}

class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({
    super.key,
    required this.genres,
    required this.initialSelectedIds,
  });

  final List<TmdbGenreDto> genres;
  final List<int> initialSelectedIds;

  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  late List<int> selected = [...widget.initialSelectedIds];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '장르 선택',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                // 0번째는 "전체", 그 뒤가 TMDB 장르
                itemCount: widget.genres.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return CheckboxListTile(
                      value: selected.isEmpty,
                      onChanged: (_) => setState(() => selected.clear()),
                      title: const Text('전체'),
                      activeColor: AppColors.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }

                  final genre = widget.genres[index - 1];
                  return CheckboxListTile(
                    value: selected.contains(genre.id),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          if (!selected.contains(genre.id)) {
                            selected.add(genre.id);
                          }
                        } else {
                          selected.remove(genre.id);
                        }
                      });
                    },
                    title: Text(genre.name),
                    activeColor: AppColors.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  child: const Text('확인'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum MovieSortOption {
  none('기본순'),
  ratingDesc('평점 높은 순'),
  yearDesc('최신순'),
  titleAsc('제목순');

  const MovieSortOption(this.label);
  final String label;
}

class GenrePreference {
  GenrePreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _selectedGenreKey = 'selected_genre';

  final SharedPreferencesAsync _preferences;

  Future<List<String>> read() async {
    return await _preferences.getStringList(_selectedGenreKey) ?? [];
  }

  Future<void> save(List<String> genre) async {
    await _preferences.setStringList(_selectedGenreKey, genre);
  }

  Future<void> clear() async {
    await _preferences.remove(_selectedGenreKey);
  }
}

class SortPreference {
  SortPreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _selectedSortKey = 'selected_sort';

  final SharedPreferencesAsync _preferences;

  Future<MovieSortOption> read() async {
    final name = await _preferences.getString(_selectedSortKey);
    return MovieSortOption.values.asNameMap()[name] ?? MovieSortOption.none;
  }

  Future<void> save(MovieSortOption option) async {
    await _preferences.setString(_selectedSortKey, option.name);
  }

  Future<void> clear() async {
    await _preferences.remove(_selectedSortKey);
  }
}
