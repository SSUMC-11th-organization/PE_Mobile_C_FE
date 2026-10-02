import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/mock_movie.dart';

class PopularMoviesSection extends StatelessWidget {
  const PopularMoviesSection({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '인기 영화',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1D1B20),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/movies'),
                child: const Row(
                  children: [
                    Text(
                      '전체보기',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4F378A),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Color(0xFF4F378A),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 272,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: movies.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              if (index == movies.length) {
                return const _ComingSoonCard();
              }
              return _PopularMovieCard(movie: movies[index], rank: index + 1);
            },
          ),
        ),
      ],
    );
  }
}

class _PopularMovieCard extends StatelessWidget {
  const _PopularMovieCard({required this.movie, required this.rank});

  final Movie movie;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/movies/${movie.id}'),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              height: 200,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      movie.posterAsset,
                      width: 140,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1D1B20),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, size: 12, color: Color(0xFFC9A74D)),
                const SizedBox(width: 4),
                Text(
                  movie.rating.toString(),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    color: Color(0xFF494551),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  const _ComingSoonCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFECE6EE),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.movie_creation_outlined,
              size: 30,
              color: Color(0xFF494551),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '개봉 예정작',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1D1B20),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'D-5',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4F378A),
            ),
          ),
        ],
      ),
    );
  }
}
