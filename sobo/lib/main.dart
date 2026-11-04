import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/movie_log_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // runApp() 전에 asset을 읽을 수 있도록 Flutter 초기화

  await dotenv.load(fileName: '.env'); // .env를 읽고 메모리에 저장할 때까지 대기

  runApp(const MovieLogApp());
}