import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/models/movie_sort.dart';
import 'package:movielog/services/genre_preference.dart';
import 'package:movielog/services/sort_preference.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('장르는 저장 전에 전체이고 저장 후 복원되며 clear하면 초기화된다', () async {
    final preference = GenrePreference();

    expect(await preference.read(), '전체');
    await preference.save('SF');
    expect(await preference.read(), 'SF');
    await preference.clear();
    expect(await preference.read(), '전체');
  });

  test('정렬은 저장 전에 기본순이고 저장 후 복원된다', () async {
    final preference = SortPreference();

    expect(await preference.read(), MovieSort.recommended);
    await preference.save(MovieSort.latest);
    expect(await preference.read(), MovieSort.latest);
  });

  test('알 수 없는 정렬 값은 기본순으로 처리한다', () {
    expect(MovieSort.fromName('unknown'), MovieSort.recommended);
    expect(MovieSort.fromName(null), MovieSort.recommended);
  });
}
