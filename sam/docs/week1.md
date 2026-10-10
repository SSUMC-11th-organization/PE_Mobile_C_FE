# 1주차 미션 - 프로필 화면

**실행 화면:** (스크린샷 첨부)

**재사용한 Widget:**
- `StatItem` (widgets/stat_item.dart): label/value만 받아 '본 영화 342 / 평점 4.2 / 즐겨찾기 58' 세 개의 통계 박스를 같은 위젯으로 그림
- `CommonAppBar` (widgets/common_app_bar.dart): title, onBack, actions를 받는 공용 AppBar로 '내 프로필' 타이틀에 사용
- 화면 내부는 `_ProfileHeader`, `_EditProfileButton`, `_ProfileStats`, `_FavoriteGenresSection`으로 나눠 build 메서드를 짧게 유지

**사용한 비트맵 이미지:**
- `assets/images/profile/profile_movielog.jpg`: `Image.asset` + `ClipOval` + `BoxFit.cover`로 128x128 원형 프로필 사진

**사용한 SVG 아이콘:**
- `assets/icons/movie.svg`: 프로필 사진 우측 하단 배지
- `assets/icons/bookmark.svg`: '선호하는 장르' 섹션 타이틀 아이콘
- 둘 다 `flutter_svg`의 `SvgPicture.asset`을 쓰고 `ColorFilter.mode(..., BlendMode.srcIn)`로 테마 색을 입힘

**교체한 MovieLog 로고 경로:**
- `assets/logos/movielog_logo.svg` (클래퍼보드 모양 SVG, 시작 화면에서 72x72로 사용)

**선택한 버튼과 선택 이유:**
- '프로필 수정' 버튼은 `TextButton` + `side: BorderSide(primary)`로 만든 아웃라인 형태
- 이 화면의 핵심 액션이 아니라 보조 액션이어서, 배경이 채워진 FilledButton 대신 테두리만 있는 가벼운 버튼으로 시각적 우선순위를 낮춤
- 모서리 radius는 ThemeData의 `textButtonTheme`에서 공통으로 적용

**사용한 주축/교차축 정렬:**
- 화면 전체 `Column`: `crossAxisAlignment: CrossAxisAlignment.start` (섹션 타이틀 왼쪽 정렬)
- 프로필 헤더 `Column`: `mainAxisSize: MainAxisSize.min` + `Center`로 가운데 정렬
- 통계 `Row`: 각 항목을 `Expanded`로 감싸서 세 칸을 같은 너비로 분배
- 장르 칩: `Wrap`(spacing/runSpacing 8)으로 화면 폭을 넘으면 자동 줄바꿈

**Padding을 적용한 위치:**
- `SingleChildScrollView`: 좌우는 `AppSpacing.screenMargin(context)`(폭 600 미만은 16, 이상은 32), 상하 16
- `StatItem` 내부: 좌우 16, 상하 12
- 프로필 사진 테두리: `EdgeInsets.all(2)`, 배지 아이콘: `EdgeInsets.all(6)`
- '프로필 수정' 버튼: 좌우 16

**Margin을 적용한 위치:**
- 프로필 사진 `Stack`을 감싼 `Container`에 `margin: EdgeInsets.only(bottom: 16)`을 줘서 이름과 간격을 둠
- 나머지 섹션 사이 간격은 `SizedBox(height: AppSpacing.lg / xl)`로 처리

**AppColors에서 관리한 값:**
- `violet #6750A4` (primary), `warmWhite #FAF9F5` (배경/surface), `white #FFFFFF` (onPrimary), `black #1C1B1F` (본문 텍스트), `gray #79747E` (보조 텍스트/outline)

**ThemeData에서 관리한 값:**
- `useMaterial3: true`, `fontFamily: 'Manrope'`
- `ColorScheme.light`: primary, onPrimary, surface, onSurface, secondary, error, outline를 AppColors로 매핑
- `scaffoldBackgroundColor`, `appBarTheme`(배경색, elevation 0, surfaceTint 제거, 상태바 아이콘 색)
- `cardTheme`, `elevatedButtonTheme`, `textButtonTheme`, `inputDecorationTheme`의 모서리 radius(8)를 통일
- 간격은 `AppSpacing`(8 단위: xs 4 / sm 8 / md 16 / lg 24 / xl 32)으로 따로 관리

**적용한 Font:**
- Manrope Variable (`assets/fonts/Manrope-VariableFont_wght.ttf`)을 pubspec.yaml에 등록하고 ThemeData의 `fontFamily`로 앱 전체에 적용
- 굵기는 `AppTextStyles`(headlineLarge 28/w700, titleLarge 24/w700, titleMedium 18/w600, bodyMedium 16/w400, bodySmall 14/w400)에서 관리

**트러블슈팅:**
- 문제: 처음에는 위젯 사이 간격을 10, 12, 20처럼 눈대중으로 그때그때 넣다 보니, 간격을 몇으로 정해야 할지 기준이 없었다. 화면마다 간격이 조금씩 달라서 전체가 정돈돼 보이지 않았다.
- 해결: 8을 기본 단위로 정하고 `AppSpacing`에 배수로 토큰을 만들었다.
  - `xs 4 / sm 8 / md 16 / lg 24 / xl 32 / xxl 48`
  - 관련 있는 요소끼리는 좁게, 다른 섹션끼리는 넓게 띄우는 기준을 세웠다.
    - 아이콘과 텍스트, 칩 사이: `sm(8)`
    - 이름과 소개 문구, 섹션 타이틀과 내용: `sm`~`md`
    - 프로필 헤더와 버튼: `lg(24)`
    - 버튼, 통계, 장르처럼 다른 섹션 사이: `xl(32)`
  - 화면 좌우 여백은 `screenMargin(context)`로 정해서, 폭 600 미만은 16, 이상은 32가 되게 했다.
- 결과: 숫자를 직접 쓰지 않고 `SizedBox(height: AppSpacing.xl)`처럼 토큰을 쓰니까 고민이 줄었다. 간격만 봐도 섹션이 구분되고, 나중에 바꿀 때도 한 곳만 고치면 된다.

**1주차 회고:**
- 화면을 작은 private 위젯으로 나누고, 색/글꼴/간격을 AppColors, AppTextStyles, AppSpacing, ThemeData로 분리하니 값을 한 곳에서 바꿀 수 있어 편했다.
- 비트맵(Image.asset)과 SVG(flutter_svg)를 같이 쓰면서 각각 언제 쓰는지, pubspec.yaml에 assets와 fonts를 등록하는 방법을 익혔다.
- 다음 주에는 공용 위젯을 더 늘리고, 하드코딩된 값(StatItem의 padding 16/12, radius 12)도 토큰으로 옮겨보고 싶다.
