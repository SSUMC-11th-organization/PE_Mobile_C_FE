import 'package:flutter/material.dart';

import '../models/movie.dart';

const mockGenres = ['드라마', 'SF', '애니메이션', '스릴러', '로맨스', '코미디', '판타지', '다큐멘터리'];

const mockMovies = <Movie>[
  Movie(
    id: '1',
    title: '별빛 아래 우리',
    year: 2024,
    genres: ['로맨스', '드라마'],
    runtime: 124,
    rating: 4.5,
    ratingCount: 1245,
    synopsis: '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 작은 천문대에서 만나게 됩니다. 매일 밤 별을 관측하며 서로의 상처를 치유하고, 잊고 있던 꿈과 사랑을 다시금 깨닫게 되는 따뜻한 이야기입니다.\n\n과거의 아픔으로 인해 사람에게 마음을 열지 못하던 여주인공은, 별자리처럼 변함없는 모습으로 자신을 기다려주는 남주인공을 통해 서서히 마음의 문을 엽니다.',
    posterColor: Color(0xFF1F2A52),
  ),
  Movie(
    id: '2',
    title: '우주의 끝에서',
    year: 2024,
    genres: ['SF'],
    runtime: 138,
    rating: 4.2,
    ratingCount: 980,
    synopsis: '지구를 떠나 우주의 끝에 도달한 탐사대원이 마주한 거대한 비밀을 그린 SF 대작입니다.',
    posterColor: Color(0xFF8C6E55),
  ),
  Movie(
    id: '3',
    title: '기억의 숲',
    year: 2022,
    genres: ['애니메이션'],
    runtime: 102,
    rating: 4.9,
    ratingCount: 2310,
    synopsis: '잃어버린 기억을 찾아 신비로운 숲을 여행하는 소녀와 정령의 이야기입니다.',
    posterColor: Color(0xFF8E9A4B),
  ),
  Movie(
    id: '4',
    title: '밤의 그림자',
    year: 2024,
    genres: ['스릴러'],
    runtime: 117,
    rating: 3.8,
    ratingCount: 640,
    synopsis: '비 내리는 도시의 밤, 사라진 증인을 쫓는 형사의 추적을 그린 스릴러입니다.',
    posterColor: Color(0xFF1E3A4C),
  ),
  Movie(
    id: '5',
    title: '봄날의 커피',
    year: 2021,
    genres: ['로맨스'],
    runtime: 109,
    rating: 4.5,
    ratingCount: 1530,
    synopsis: '작은 카페에서 시작되는 두 사람의 느리고 따뜻한 봄날의 사랑 이야기입니다.',
    posterColor: Color(0xFFC9A98B),
  ),
  Movie(
    id: '6',
    title: '도시의 선',
    year: 2023,
    genres: ['다큐멘터리'],
    runtime: 95,
    rating: 4.1,
    ratingCount: 410,
    synopsis: '도시를 구성하는 선과 면, 건축가들의 시선으로 바라본 도시 다큐멘터리입니다.',
    posterColor: Color(0xFFA9ADB5),
  ),
  Movie(
    id: '7',
    title: '마션 레스큐',
    year: 2023,
    genres: ['SF', '드라마'],
    runtime: 131,
    rating: 4.6,
    ratingCount: 1890,
    synopsis: '화성에 홀로 남겨진 대원을 구하기 위한 구조대의 필사적인 임무를 그립니다.',
    posterColor: Color(0xFF5A1F1F),
  ),
  Movie(
    id: '8',
    title: '스파이 코드',
    year: 2022,
    genres: ['스릴러', '코미디'],
    runtime: 120,
    rating: 4.2,
    ratingCount: 870,
    synopsis: '평범한 회사원이 암호를 해독하며 세계적인 음모에 휘말리는 유쾌한 스파이 코미디입니다.',
    posterColor: Color(0xFF2E5E8C),
  ),
  Movie(
    id: '9',
    title: '비오는 날의 꿈',
    year: 2020,
    genres: ['판타지', '드라마'],
    runtime: 112,
    rating: 3.9,
    ratingCount: 520,
    synopsis: '비가 오는 날에만 열리는 문을 통해 다른 세계를 오가는 소년의 이야기입니다.',
    posterColor: Color(0xFF2F5D62),
  ),
];

// 홈 상단에 크게 보여줄 추천 영화
Movie get featuredMovie => mockMovies.first;

Movie? findMovieById(String id) {
  for (final movie in mockMovies) {
    if (movie.id == id) return movie;
  }
  return null;
}
