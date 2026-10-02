import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:movielog/data/mock_movie.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/widgets/movie/movie_rating_input.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final int movieId;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final movie = findMovieById(widget.movieId);

    if (movie == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('영화를 찾을 수 없습니다.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 고정된 TopAppBar
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: AppColors.surface,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.primary,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Cinema Archive',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // 스크롤 가능한 본문
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Section (이제 노치 아래부터 시작)
                    SizedBox(
                      height: 585,
                      width: double.infinity,
                      child: Image.asset(movie.posterAsset, fit: BoxFit.cover),
                    ),
                    // Information Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1B1C1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${movie.year} • ${movie.genre} • ${movie.runtimeMinutes}분',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              color: Color(0xFF494551),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                RatingBarIndicator(
                                  rating: movie.rating,
                                  itemCount: 5,
                                  itemSize: 16.67,
                                  itemBuilder: (context, index) => const Icon(
                                    Icons.star,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  movie.rating.toString(),
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1B1C1A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${movie.ratingCount})',
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                    color: Color(0xFF494551),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (movie.tags.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Wrap(
                                spacing: 8,
                                children: movie.tags
                                    .map(
                                      (tag) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE3E2DF),
                                          borderRadius: BorderRadius.circular(
                                            9999,
                                          ),
                                        ),
                                        child: Text(
                                          tag,
                                          style: const TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF494551),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Synopsis Section
                    if (movie.synopsis.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFFCBC4D2)),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '시놉시스',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1B1C1A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              movie.synopsis,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                height: 26 / 16,
                                letterSpacing: 0.5,
                                color: Color(0xFF494551),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: Color(0xFFCBC4D2))),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => isFavorite = !isFavorite);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFavorite
                              ? 'Mock 즐겨찾기에 추가했습니다.'
                              : 'Mock 즐겨찾기에서 삭제했습니다.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                  label: const Text('즐겨찾기'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final rating = await showDialog<double>(
                      context: context,
                      builder: (context) => const _RatingDialog(),
                    );

                    if (rating != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('평점 $rating점을 남겼습니다.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    elevation: 1,
                  ),
                  icon: const Icon(Icons.star_border),
                  label: const Text('평점 남기기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingDialog extends StatefulWidget {
  const _RatingDialog();

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  double rating = 0;
  bool submitted = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: submitted ? _buildSubmittedView() : _buildSelectingView(),
        ),
      ),
    );
  }

  List<Widget> _buildSelectingView() {
    return [
      const Text(
        '영화는 어떠셨나요?',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 24),
      MovieRatingInput(
        rating: rating,
        onChanged: (value) {
          setState(() => rating = value);
        },
      ),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: rating == 0 ? null : () => setState(() => rating = 0),
            child: const Text('초기화'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: rating == 0
                ? null
                : () => setState(() => submitted = true),
            child: const Text('확인'),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildSubmittedView() {
    return [
      const Icon(Icons.check_circle, color: Colors.amber, size: 40),
      const SizedBox(height: 16),
      Text(
        '$rating점을 저장했습니다',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => setState(() => submitted = false),
            child: const Text('다시 선택하기'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, rating),
            child: const Text('닫기'),
          ),
        ],
      ),
    ];
  }
}
