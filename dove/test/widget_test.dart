import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screen/home_screen.dart';
import 'package:movielog/screen/movie_detail_screen.dart';
import 'package:movielog/screen/start_screen.dart';

Uri currentUri() => AppRouter.router.routerDelegate.currentConfiguration.uri;

void main() {
  testWidgets('앱 실행 시 시작 화면이 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(StartScreen), findsOneWidget);
  });

  testWidgets('영화 목록에서 장르 필터, 상세 이동과 뒤로 가기가 동작한다', (tester) async {
    await tester.pumpWidget(const MyApp());
    AppRouter.router.go('/movies');
    await tester.pumpAndSettle();

    expect(find.text('별빛 아래 우리'), findsWidgets);
    expect(find.text('우주의 끝에서'), findsWidgets);

    // 체크만 하고 닫으면 목록은 그대로, 확인을 눌러야 필터가 적용된다
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SF'));
    await tester.pumpAndSettle();
    expect(find.text('별빛 아래 우리'), findsWidgets);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('별빛 아래 우리'), findsNothing);
    expect(find.text('우주의 끝에서'), findsWidgets);
    expect(currentUri().toString(), '/movies?genre=SF');

    // 선택을 모두 해제하고 확인하면 전체가 다시 보인다
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(currentUri().toString(), '/movies');
    await tester.tap(find.text('별빛 아래 우리').first);
    await tester.pumpAndSettle();
    expect(find.byType(MovieDetailScreen), findsOneWidget);

    AppRouter.router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(MovieDetailScreen), findsNothing);
  });

  testWidgets('상세에서 즐겨찾기 Snackbar와 평점 Dialog가 동작한다', (tester) async {
    await tester.pumpWidget(const MyApp());
    AppRouter.router.go('/home');
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    AppRouter.router.push('/movies/1');
    await tester.pumpAndSettle();

    await tester.tap(find.text('즐겨찾기'));
    await tester.pump();
    expect(find.text('즐겨찾기에 추가했어요.'), findsOneWidget);

    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    expect(find.text('영화는 어떠셨나요?'), findsOneWidget);
  });

  testWidgets('URL의 Query Parameter로 장르 필터가 적용된다', (tester) async {
    await tester.pumpWidget(const MyApp());
    AppRouter.router.go('/movies?genre=SF');
    await tester.pumpAndSettle();

    expect(find.text('별빛 아래 우리'), findsNothing);
    expect(find.text('우주의 끝에서'), findsWidgets);
  });

  testWidgets('탭을 오가도 영화 탭의 필터 상태가 유지된다', (tester) async {
    await tester.pumpWidget(const MyApp());
    AppRouter.router.go('/movies?genre=SF');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.movie_outlined));
    await tester.pumpAndSettle();
    expect(currentUri().toString(), '/movies?genre=SF');
    expect(find.text('별빛 아래 우리'), findsNothing);
  });
}
