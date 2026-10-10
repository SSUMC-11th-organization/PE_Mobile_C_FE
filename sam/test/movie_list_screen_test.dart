// 영화 목록 화면 테스트
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/services/fake_movie_service.dart';
import 'package:movielog/services/genre_preference_store.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/movie_poster_card.dart';

// 테스트용 메모리 저장소 (실제 SharedPreferences 대신 사용)
class _MemoryGenreStore extends GenrePreferenceStore {
  _MemoryGenreStore([this.savedGenre]);

  String? savedGenre;

  @override
  Future<String?> load() async => savedGenre;

  @override
  Future<void> save(String genre) async => savedGenre = genre;
}

void main() {
  void setPhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpMovieList(
    WidgetTester tester, {
    MovieLoadMode mode = MovieLoadMode.success,
    GenrePreferenceStore? store,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MovieListScreen(
          mode: mode,
          genreStore: store ?? _MemoryGenreStore(),
        ),
      ),
    );
  }

  bool isChipSelected(WidgetTester tester, String label) {
    return tester
        .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
        .selected;
  }

  testWidgets('shows all movies and filters them by genre', (
    WidgetTester tester,
  ) async {
    setPhoneSize(tester);
    await pumpMovieList(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MoviePosterCard), findsNWidgets(2));
    expect(find.text('별빛 아래 우리'), findsOneWidget);
    expect(find.text('우주의 끝에서'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'SF'));
    await tester.pump();

    expect(find.byType(MoviePosterCard), findsOneWidget);
    expect(find.text('우주의 끝에서'), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsNothing);
  });

  testWidgets('shows empty message when there are no movies', (
    WidgetTester tester,
  ) async {
    await pumpMovieList(tester, mode: MovieLoadMode.empty);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('표시할 영화가 없습니다.'), findsOneWidget);
    expect(find.byType(MoviePosterCard), findsNothing);
  });

  testWidgets('shows error message with retry when loading fails', (
    WidgetTester tester,
  ) async {
    await pumpMovieList(tester, mode: MovieLoadMode.failure);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('영화를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('saves the selected genre and restores it on rebuild', (
    WidgetTester tester,
  ) async {
    setPhoneSize(tester);
    final store = _MemoryGenreStore();

    await pumpMovieList(tester, store: store);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.widgetWithText(ChoiceChip, 'SF'));
    await tester.pump();

    expect(store.savedGenre, 'SF');

    // 화면을 없앴다가 같은 저장소로 다시 만든다 (앱 재실행과 같은 상황)
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await pumpMovieList(tester, store: store);
    await tester.pump(const Duration(seconds: 1));

    expect(isChipSelected(tester, 'SF'), isTrue);
    expect(find.byType(MoviePosterCard), findsOneWidget);
    expect(find.text('우주의 끝에서'), findsOneWidget);
  });

  testWidgets('falls back to all genres when the saved genre is missing', (
    WidgetTester tester,
  ) async {
    setPhoneSize(tester);
    await pumpMovieList(tester, store: _MemoryGenreStore('없는 장르'));
    await tester.pump(const Duration(seconds: 1));

    expect(isChipSelected(tester, '전체'), isTrue);
    expect(find.byType(MoviePosterCard), findsNWidgets(2));
  });
}
