import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/movie_widget/genre_filter_sheet.dart';
import '../widgets/movie_widget/movie_card.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key, this.selectedGenres = const {}});

  /// URL의 Query Parameter(genre)에서 읽은 선택 장르. 비어 있으면 전체.
  final Set<String> selectedGenres;

  Future<void> _openFilter(BuildContext context) async {
    final result = await showGenreFilterSheet(
      context,
      genres: mockGenres,
      selectedGenres: selectedGenres,
    );
    if (result == null || !context.mounted) return;

    // 선택 결과를 상태가 아닌 URL로 반영한다
    final uri = Uri(
      path: '/movies',
      queryParameters: result.isEmpty ? null : {'genre': result.toList()},
    );
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final movies = moviesByGenres(selectedGenres);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '영화',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => debugPrint('검색 버튼을 눌렀습니다.'),
            icon: const Icon(Icons.search, color: AppColors.primary),
          ),
        ],
      ),
      body: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => _openFilter(context),
              icon: Icon(
                Icons.filter_list,
                color: selectedGenres.isEmpty
                    ? AppColors.gray
                    : AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: movies.isEmpty
                ? const Center(child: Text('해당 장르의 영화가 없어요.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: movies.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.62,
                        ),
                    itemBuilder: (context, index) =>
                        MovieCard(movie: movies[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
