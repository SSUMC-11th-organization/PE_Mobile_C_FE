import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/theme/app_colors.dart';
// import 'package:movielog/theme/app_text_styles.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/widgets/movie_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, this.initialGenres = const []});

  final List<String> initialGenres;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  //static const allGenres = ['드라마', 'SF', '애니메이션', '스릴러', '로맨스', '액션', '다큐멘터리'];

  // late Set<String> appliedGenres = widget.initialGenres.toSet();

  // final genrePreference = GenrePreference();
  // final sortPreference = SortPreference();

  // MovieSortOption sortOption = MovieSortOption.none;

  // @override
  // void initState() {
  //   super.initState();
  //   _restorePreferences();
  // }

  // List<Movie> _sorted(List<Movie> list) {
  //   final copy = list.toList();
  //   switch (sortOption) {
  //     case MovieSortOption.none:
  //       break;
  //     case MovieSortOption.ratingDesc:
  //       copy.sort((a, b) => b.rating.compareTo(a.rating));
  //       break;
  //     case MovieSortOption.titleAsc:
  //       copy.sort((a, b) => a.title.compareTo(b.title));
  //       break;
  //     case MovieSortOption.yearDesc:
  //       copy.sort((a, b) => b.year.compareTo(a.year));
  //       break;
  //   }
  //   return copy;
  // }

  // Future<void> _restorePreferences() async {
  //   final savedSort = await sortPreference.read();
  //
  //   final savedGenres = widget.initialGenres.isEmpty
  //       ? (await genrePreference.read()).toSet()
  //       : null;
  //
  //   if (!mounted) return;
  //   setState(() {
  //     sortOption = savedSort;
  //     if (savedGenres != null) appliedGenres = savedGenres;
  //   });
  // }

  // Future<void> _openFilterSheet() async {
  //   final result = await showModalBottomSheet<Set<String>>(
  //     context: context,
  //     isScrollControlled: true,
  //     useSafeArea: true,
  //     builder: (context) => GenreFilterSheet(
  //       allGenres: allGenres,
  //       initialSelected: appliedGenres,
  //     ),
  //   );

  //   if (result == null) return;
  //   if (!mounted) return;

  //   genrePreference.save(result.toList());

  //   setState(() => appliedGenres = result);

  //   final location = result.isEmpty
  //       ? '/movies'
  //       : Uri(
  //           path: '/movies',
  //           queryParameters: {'genre': result.join(',')},
  //         ).toString();

  //   context.go(location);
  // }

  // Future<void> _openSortSheet() async {
  //   final result = await showModalBottomSheet<MovieSortOption>(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
  //     ),
  //     builder: (context) => SortOptionSheet(selected: sortOption),
  //   );

  //   if (result == null) return;
  //   if (!mounted) return;
  //   setState(() => sortOption = result);
  //   sortPreference.save(result);
  // }

  late final MovieListViewModel _viewModel;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<MovieListViewModel>();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (!_viewModel.hasRetryableFailure || _isDialogShowing) return;
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
      _viewModel.retry();
    } else {
      _viewModel.restoreLastSuccessGenres();
    }
  }

  Future<void> _openGenreSheet() async {
    final viewModel = context.read<MovieListViewModel>();

    final result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => GenreFilterSheet(
        genres: viewModel.genres,
        initialSelectedIds: viewModel.selectedGenreIds,
      ),
    );

    if (result == null || !mounted) return;
    if (listEquals(result, viewModel.selectedGenreIds)) return;

    await viewModel.selectGenres(result);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MovieListViewModel>();
    final isLoading = viewModel.status == MovieListLoadStatus.loading;

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
        // bottom: PreferredSize(
        //   preferredSize: const Size.fromHeight(56),
        //   child: SizedBox(
        //     height: 56,
        //     child: ListView(
        //       scrollDirection: Axis.horizontal,
        //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //       children: [
        //         ChoiceChip(
        //           label: const Text('전체'),
        //           labelStyle: AppTextStyles.bodySmall.copyWith(
        //             fontWeight: FontWeight.w500,
        //             color: viewModel.selectedGenreId == null
        //                 ? AppColors.warmWhite
        //                 : AppColors.onSurface,
        //           ),
        //           showCheckmark: false,
        //           labelPadding: EdgeInsets.zero,
        //           backgroundColor: AppColors.primaryContainer,
        //           side: BorderSide.none,
        //           padding: const EdgeInsets.symmetric(
        //             horizontal: 16,
        //             vertical: 8,
        //           ),
        //           shape: RoundedRectangleBorder(
        //             borderRadius: BorderRadius.circular(9999),
        //           ),
        //           selected: viewModel.selectedGenreId == null,
        //           selectedColor: AppColors.primary,
        //           onSelected: isLoading
        //               ? null
        //               : (_) => viewModel.selectGenre(null),
        //         ),
        //         for (final genre in viewModel.genres) ...[
        //           const SizedBox(width: 8),
        //           ChoiceChip(
        //             label: Text(genre.name),
        //             labelStyle: AppTextStyles.bodySmall.copyWith(
        //               fontWeight: FontWeight.w500,
        //               color: viewModel.selectedGenreId == genre.id
        //                   ? AppColors.warmWhite
        //                   : AppColors.onSurface,
        //             ),
        //             showCheckmark: false,
        //             labelPadding: EdgeInsets.zero,
        //             backgroundColor: AppColors.primaryContainer,
        //             side: BorderSide.none,
        //             padding: const EdgeInsets.symmetric(
        //               horizontal: 16,
        //               vertical: 8,
        //             ),
        //             shape: RoundedRectangleBorder(
        //               borderRadius: BorderRadius.circular(9999),
        //             ),
        //             selected: viewModel.selectedGenreId == genre.id,
        //             selectedColor: AppColors.primary,
        //             onSelected: isLoading
        //                 ? null
        //                 : (_) => viewModel.selectGenre(genre.id),
        //           ),
        //         ],
        //       ],
        //     ),
        //   ),
        // ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: AppColors.onPrimaryContainer),
          ),
          IconButton(
            onPressed: (isLoading || viewModel.genres.isEmpty)
                ? null
                : _openGenreSheet,
            icon: Icon(
              Icons.filter_list,
              color: viewModel.selectedGenreIds.isEmpty
                  ? AppColors.onSurfaceVariant
                  : AppColors.primary,
            ),
          ),
          // IconButton(
          //   onPressed: _openSortSheet,
          //   icon: Icon(
          //     Icons.sort,
          //     color: sortOption == MovieSortOption.none
          //         ? AppColors.onSurfaceVariant
          //         : AppColors.primary,
          //   ),
          // ),
        ],
      ),
      body: switch (viewModel.status) {
        MovieListLoadStatus.idle ||
        MovieListLoadStatus.loading => const MovieListLoading(),
        MovieListLoadStatus.error => MovieListError(
          message: viewModel.message,
          onRetry: () => viewModel.loadInitial(),
        ),
        MovieListLoadStatus.empty => const MovieListEmpty(),
        MovieListLoadStatus.success => RefreshIndicator(
          onRefresh: () => viewModel.refresh(),
          child: MovieGrid(movies: viewModel.movies),
        ),
      },
    );
  }
}

class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  final List<TmdbMovieDto> movies;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: movies.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 24,
          childAspectRatio: 171 / 316.5,
        ),
        itemBuilder: (context, index) {
          return MovieCard(movie: movies[index]);
        },
        physics: const AlwaysScrollableScrollPhysics(),
      ),
    );
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
