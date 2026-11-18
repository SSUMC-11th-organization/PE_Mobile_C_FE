// MovieLog v5 서버 대신 경로별로 정해진 응답을 돌려주는 테스트 도우미
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/token_storage.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/session_ratings_store.dart';

// (상태 코드, 응답 JSON) — JSON은 Map이나 List 모두 가능
typedef FakeRoute = (int, Object) Function(RequestOptions options);

class FakeMovieLogAdapter implements HttpClientAdapter {
  FakeMovieLogAdapter(this.route);

  FakeRoute route;
  // 설정하면 complete될 때까지 응답을 보류 (통신 중 상태 확인용)
  Completer<void>? gate;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    await gate?.future;
    final (status, json) = route(options);
    return ResponseBody.fromString(
      jsonEncode(json),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio fakeDio(FakeMovieLogAdapter adapter, {String baseUrl = 'https://fake'}) =>
    Dio(BaseOptions(baseUrl: baseUrl))..httpClientAdapter = adapter;

// 공개 조회용·인증용 Dio 자리에 같은 가짜 서버를 연결
RatingApiService fakeRatingService(FakeMovieLogAdapter adapter) {
  final dio = fakeDio(adapter);
  return RatingApiService(dio, dio);
}

// v7 등록·수정 성공 응답 (CommonResponse 안에 평점 하나)
Map<String, Object> ratingResultJson({
  int ratingId = 3,
  int movieId = 13,
  int score = 4,
  String? comment,
}) => {
  'isSuccess': true,
  'code': 'COMMON200',
  'message': '성공',
  'result': {
    'ratingId': ratingId,
    'movieId': movieId,
    'score': score,
    'comment': comment,
    'createdAt': '2026-11-03T19:00:09.148Z',
    'updatedAt': '2026-11-18T10:00:00.000Z',
  },
};

// 실제 서버 응답과 같은 모양 (1번 회원)
List<Map<String, dynamic>> sampleRatingsJson() => [
  {
    'ratingId': 3,
    'movieId': 13,
    'score': 3,
    'comment': null,
    'createdAt': '2026-11-03T19:00:09.148Z',
    'updatedAt': '2026-11-03T19:00:09.148Z',
  },
  {
    'ratingId': 1,
    'movieId': 550,
    'score': 5,
    'comment': '최고의 영화!',
    'createdAt': '2026-11-03T19:00:09.148Z',
    'updatedAt': '2026-11-03T19:00:09.148Z',
  },
];

// TMDB /movie/{id} 상세 응답 (genres가 객체 배열)
Map<String, dynamic> movieDetailJson(int id) => {
  'id': id,
  'title': '영화 $id',
  'overview': '',
  'poster_path': '/p$id.jpg',
  'release_date': '1999-10-15',
  'genres': [
    {'id': 18, 'name': '드라마'},
  ],
};

// 테스트용 메모리 토큰 저장소
class MemoryTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<void> saveAccessToken(String token) async => this.token = token;

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<void> deleteAccessToken() async => token = null;
}

// 로그인·내 정보 요청에 성공 응답을 주는 AuthViewModel (signIn()으로 로그인 상태를 만듦)
AuthViewModel fakeAuthViewModel() {
  final dio = fakeDio(
    FakeMovieLogAdapter(
      (options) => options.path == '/v7/auth/login'
          ? (
              200,
              {
                'isSuccess': true,
                'code': 'COMMON200',
                'message': '로그인 성공',
                'result': {'nickname': '무비러버', 'accessToken': 'token-abc'},
              },
            )
          : (
              200,
              {
                'isSuccess': true,
                'code': 'COMMON200',
                'message': '조회 성공',
                'result': {
                  'email': 'movie@example.com',
                  'nickname': '무비러버',
                  'createdAt': '2026-11-18T10:30:00',
                },
              },
            ),
    ),
  );
  return AuthViewModel(
    AuthApiService(dio),
    MemberApiService(dio),
    MemoryTokenStorage(),
  );
}

// 로그인하고 내 정보까지 불러온 상태로 만듦
Future<void> signIn(AuthViewModel auth) async {
  await auth.login('movie@example.com', 'pw1234');
  await auth.loadMember();
}

// 이번 세션에 등록한 평점을 미리 넣어 둔 저장소 (json 순서 그대로 보이게 넣음)
SessionRatingsStore seededRatingsStore(
  AuthViewModel auth, [
  List<Map<String, dynamic>>? ratingsJson,
]) {
  final store = SessionRatingsStore(auth);
  for (final json in (ratingsJson ?? sampleRatingsJson()).reversed) {
    store.add(RatingDto.fromJson(json));
  }
  return store;
}
