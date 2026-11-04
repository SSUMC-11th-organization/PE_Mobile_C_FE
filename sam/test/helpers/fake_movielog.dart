// MovieLog v5 서버 대신 경로별로 정해진 응답을 돌려주는 테스트 도우미
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

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
