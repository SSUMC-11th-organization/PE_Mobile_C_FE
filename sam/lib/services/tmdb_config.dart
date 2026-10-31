// .env에서 읽는 TMDB 설정 값 (main()에서 dotenv.load()를 마친 뒤에 읽어야 함)
import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class TmdbConfig {
  static String get accessToken => dotenv.env['TMDB_ACCESS_TOKEN'] ?? '';
}
