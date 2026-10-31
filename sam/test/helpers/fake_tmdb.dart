// 실제 서버 대신 정해진 응답을 돌려주는 TMDB 테스트 도우미
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:movielog/services/tmdb_movie_service.dart';

// 요청별로 (상태 코드, 응답 JSON)을 정하는 함수
typedef FakeResponder = (int, Map<String, dynamic>) Function(
  RequestOptions options,
);

class FakeTmdbAdapter implements HttpClientAdapter {
  FakeTmdbAdapter({
    this.statusCode = 200,
    this.body = const {},
    this.responder,
  });

  int statusCode;
  Map<String, dynamic> body;
  FakeResponder? responder;
  // 설정하면 complete될 때까지 응답을 보류 (요청 중 상태 확인용)
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
    final (status, json) = responder?.call(options) ?? (statusCode, body);
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

TmdbMovieService fakeTmdbService(FakeTmdbAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.themoviedb.org/3'))
    ..httpClientAdapter = adapter;
  return TmdbMovieService(dio);
}

Map<String, dynamic> moviePageJson(int count, {bool withPoster = true}) => {
  'page': 1,
  'total_pages': 1,
  'total_results': count,
  'results': [
    for (var i = 1; i <= count; i++)
      {
        'id': 100 + i,
        'title': '인기 영화 $i',
        'genre_ids': [18],
        'poster_path': withPoster ? '/poster$i.jpg' : null,
        'release_date': '2025-0$i-01',
      },
  ],
};

Map<String, dynamic> genreListJson() => {
  'genres': [
    {'id': 28, 'name': '액션'},
    {'id': 18, 'name': '드라마'},
  ],
};

// 지정한 id로 Discover 한 페이지 응답을 만듦
Map<String, dynamic> discoverPageJson(
  Iterable<int> ids, {
  int page = 1,
  int totalPages = 1,
}) => {
  'page': page,
  'total_pages': totalPages,
  'total_results': ids.length * totalPages,
  'results': [
    for (final id in ids)
      {
        'id': id,
        'title': '영화 $id',
        'genre_ids': [18],
        'poster_path': null,
        'release_date': '2025-01-01',
      },
  ],
};
