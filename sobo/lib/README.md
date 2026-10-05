# 코드 폴더 안내

현재 학습 코드의 `screens`, `services`, `widgets` 구분을 유지하고, 각 폴더 안에서 관련 기능을 묶는다.

| 폴더 | 역할 |
| --- | --- |
| `data/` | 기존 Movie 모델과 Mock 영화 목록 |
| `enums/` | 선택 가능한 값을 정의하는 타입. `MovieLoadMode` 등 |
| `router/` | 화면 경로와 이동 설정 |
| `screens/auth/` | 시작·회원가입 화면 |
| `screens/home/` | 홈 화면 |
| `screens/movie/` | 영화 목록·상세 화면 |
| `screens/profile/` | 프로필 화면 |
| `screens/main_screen.dart` | 하단 탭과 전체 화면 틀 |
| `services/movie/` | 영화 조회 서비스와 조회 예외 |
| `services/storage/` | 마지막 선택 장르의 로컬 저장·읽기 |
| `theme/` | 공용 색상과 테마 |
| `widgets/common/` | 여러 화면에서 사용하는 공용 위젯 |
| `widgets/home/` | 홈 화면의 인기 영화 목록 |
| `widgets/movie/cards/` | 영화 카드와 Grid 배치 |
| `widgets/movie/filters/` | 장르 필터 시트 |
| `widgets/movie/ratings/` | 평점 입력과 다이얼로그 |
| `widgets/movie/states/` | Loading·Empty·Error 화면 |
| `widgets/profile/` | 프로필 화면의 부분 위젯 |
| `widgets/sign_up/` | 회원가입 입력 위젯 |

`test/auth/`에는 회원가입 테스트, `test/movie/`에는 영화 목록 테스트를 둔다.

## Mock 모드 사용

`MovieLoadMode`는 서비스 파일에서 분리되어 `enums/movie_load_mode.dart`에 있다. 화면에서 모드를 명시하려면 서비스와 enum을 각각 import한다.

```dart
import '../../enums/movie_load_mode.dart';
import '../../services/movie/fake_movie_service.dart';
```

위 상대 경로는 `screens/movie/movie_list_screen.dart` 기준이다.

```dart
_moviesFuture = movieService.fetchMovies(mode: MovieLoadMode.failure);
```

`MovieLoadException`을 직접 확인하는 코드는 `services/movie/movie_load_exception.dart`를 별도로 import한다.

## 파일을 추가할 때

- 화면 전체는 `screens/`, 화면 일부는 `widgets/`에 둔다.
- 데이터 조회는 `services/movie/`, 로컬 설정 저장은 `services/storage/`에 둔다.
- 서비스가 UI를 만들거나 위젯이 저장소 구현을 갖지 않도록 역할을 구분한다.
- 같은 역할의 기존 폴더가 있으면 그곳에 추가하고, 새 역할이 필요할 때만 폴더를 만든다.
