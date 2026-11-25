import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import '../widgets/movie_page_footer.dart';
import '../widgets/movielog_button.dart';

class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key, required this.onOpenMovie});

  final Future<void> Function(TmdbMovieDto movie) onOpenMovie;

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final text = TextEditingController();

  Timer? _debounce;
  String submittedQuery = '';
  String? inputError;

  // 입력이 멈춘 뒤 500ms가 지나면 마지막 검색어로 한 번만 검색합니다.
  void _onChanged(String value) {
    _debounce?.cancel(); // 입력할 때마다 이전 타이머를 취소합니다.
    if (inputError != null) setState(() => inputError = null);

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final query = value.trim();
      if (query.isEmpty) return; // 빈 검색어는 서버에 보내지 않습니다.

      // 공백만 달라진 같은 검색어는 다시 요청하지 않습니다(오류 상태는 예외).
      final vm = context.read<PagedMoviesViewModel>();
      if (query == submittedQuery && vm.phase != LoadPhase.error) return;

      _search(query);
    });
  }

  void _search(String query) {
    setState(() {
      inputError = null;
      submittedQuery = query;
    });
    context.read<PagedMoviesViewModel>().loadInitial(query: query);
  }

  // 제출(키보드 검색 / '검색' 버튼): 기다리지 않고 바로 검색합니다.
  void submitSearch(String value) {
    _debounce?.cancel();
    final query = value.trim();

    if (query.isEmpty) {
      setState(() => inputError = '검색어를 입력합니다.');
      return;
    }

    _search(query);
  }

  @override
  void dispose() {
    _debounce?.cancel(); // 대기 중인 타이머를 정리합니다.
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.surface,
    appBar: AppBar(
      backgroundColor: AppColors.surface,
      title: const Text('영화 검색'),
      centerTitle: true,
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: text,
            textInputAction: TextInputAction.search,
            onSubmitted: submitSearch,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: '검색어 예시',
              errorText: inputError,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              suffixIcon: TextButton(
                onPressed: () => submitSearch(text.text),
                child: const Text(
                  '검색',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Consumer<PagedMoviesViewModel>(
            builder: (context, vm, _) {
              if (vm.phase == LoadPhase.idle) {
                return const Center(child: Text('검색어를 입력합니다.'));
              }

              if (vm.phase == LoadPhase.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (vm.phase == LoadPhase.error) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        vm.errorMessage ?? '검색 결과를 불러오지 못했습니다.',
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
                        onPressed: () => vm.loadInitial(query: submittedQuery),
                      ),
                    ],
                  ),
                );
              }

              if (vm.phase == LoadPhase.empty) {
                return const Center(
                  child: Text(
                    '검색 결과가 없습니다.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: vm.movies.length + 1,
                itemBuilder: (context, index) {
                  if (index == vm.movies.length) {
                    return MoviePageFooter(vm: vm, moreLabel: '검색 결과 더 보기');
                  }

                  final movie = vm.movies[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SearchResultCard(
                      movie: movie,
                      onTap: () => widget.onOpenMovie(movie),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.movie, required this.onTap});

  final TmdbMovieDto movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final path = movie.posterPath;
    final year = (movie.releaseDate != null && movie.releaseDate!.length >= 4)
        ? movie.releaseDate!.substring(0, 4)
        : null;

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
                      movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (year != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        year,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      movie.overview.isEmpty ? '줄거리 정보가 없습니다.' : movie.overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
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
