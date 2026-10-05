import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/mock_movies.dart';
import '../../../theme/app_colors.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie, this.compact = false});

  final Movie movie;
  final bool compact; // true: 영화 목록용 작은 카드, false: 홈 화면용 큰 카드

  @override
  Widget build(BuildContext context) {
    // 영화 목록에서의 Movie card 1개
    if (compact) {
      return GestureDetector(
        // 영화 상세 페이지로
        onTap: () => context.push('/movies/${movie.id}'),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  movie.posterAsset,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Text(
                      movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('${movie.year} · ${movie.genre}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 홈화면의 큰 포스터 카드
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/movies/${movie.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 440,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(movie.posterAsset, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${movie.genre} · ${movie.year}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Text(
                          '상세보기',
                          style: TextStyle(color: Colors.white),
                        ),
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
