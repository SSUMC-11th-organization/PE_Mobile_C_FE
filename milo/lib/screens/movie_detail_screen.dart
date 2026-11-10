import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/widgets/movie_card.dart';
import 'package:movielog/widgets/rating_dialog.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/models/tmdb_movie_detail_dto.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MovieDetailViewModel>();
    final movie = viewModel.movie;

    // 장르·상영 시간·투표 수는 상세 조회 DTO에만 있습니다.
    // 목록에서 받은 기본 DTO(extra)로 열리면 detail은 null이라 해당 항목은 숨깁니다.
    final detail = movie is TmdbMovieDetailDto ? movie : null;
    final genres = detail?.genres ?? [];
    final runtime = detail?.runtime;
    final canRate = viewModel.memberId != null; // 회원가입 전에는 등록 버튼 비활성화

    final subtitle = [
      if (detail != null) detail.year,
      if (genres.isNotEmpty) genres.map((g) => g.name).join(', '),
      if (runtime != null && runtime > 0) '$runtime분',
    ].join(' • ');

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
                      Icons.share_outlined,
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
                    TmdbPosterImage(
                      posterPath: movie.posterPath,
                      width: double.infinity,
                      height: 585,
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
                          // Text(
                          //   '${movie.year} • ${movie.genre} • ${movie.runtimeMinutes}분',
                          //   style: const TextStyle(
                          //     fontFamily: 'Manrope',
                          //     fontSize: 14,
                          //     color: Color(0xFF494551),
                          //   ),
                          // ),
                          Text(
                            subtitle,
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
                                  // rating: movie.rating,
                                  rating: movie.voteAverage / 2,
                                  itemCount: 5,
                                  itemSize: 16.67,
                                  itemBuilder: (context, index) => const Icon(
                                    Icons.star,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  // movie.rating.toString(),
                                  movie.voteAverage.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1B1C1A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  detail == null ? '' : '(${detail.voteCount})',
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                    color: Color(0xFF494551),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (genres.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: genres
                                    .map(
                                      (genre) => Container(
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
                                          genre.name,
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
                    if (movie.overview.isNotEmpty)
                      Container(
                        width: double.infinity,
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
                              // movie.synopsis,
                              movie.overview,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 가입 전에는 평점을 남길 수 없으니 회원가입으로 안내합니다.
              if (!canRate)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('평점을 남기려면 먼저 학습용 회원가입이 필요합니다.'),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: const Text('회원가입'),
                      ),
                    ],
                  ),
                ),
              Row(
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
                        isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      ),
                      label: const Text('즐겨찾기'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: canRate
                          ? () async {
                              final saved = await showDialog<bool>(
                                context: context,
                                barrierDismissible:
                                    false, // 저장 중 바깥 탭으로 닫히는 것도 막습니다.
                                builder: (_) => RatingDialog(
                                  onSubmit: (score, comment) async {
                                    final viewModel = context
                                        .read<MovieDetailViewModel>();
                                    await viewModel.createRating(
                                      score: score,
                                      comment: comment,
                                    );
                                    if (viewModel.submitStatus !=
                                        SubmitStatus.success) {
                                      throw StateError(
                                        viewModel.submitMessage ??
                                            '저장에 실패했습니다.',
                                      );
                                    }
                                  },
                                ),
                              );

                              if (!context.mounted || saved != true) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.',
                                  ),
                                ),
                              );
                            }
                          : null,
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
            ],
          ),
        ),
      ),
    );
  }
}
