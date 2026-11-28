# 코드 폴더 안내

| 경로 | 역할 |
| --- | --- |
| `app/`, `router/` | 앱 의존성 등록 및 화면 경로 |
| `core/network/`, `core/session/` | HTTP 클라이언트와 로그인 세션 확인 |
| `core/utils/` | 동시 요청 제한과 화면 종료 이후 상태 알림 보호 |
| `data/models/` | API 요청·응답 모델 |
| `data/services/` | 인증·회원가입·내 정보·평점·즐겨찾기·TMDB 연동과 토큰 저장 |
| `view_models/` | 화면 상태와 API 호출 흐름 |
| `screens/` | 영화 상세·영화 목록·검색·마이페이지·즐겨찾기 등 전체 화면 |
| `widgets/` | 영화 카드, 즐겨찾기 버튼, 더 보기 영역 등 화면 구성 요소 |

영화 목록과 영화 검색은 각각 `PagedMoviesViewModel`을 사용한다. `MovieListViewModel`은 영화 목록의 장르 조회와 선택을 담당한다. 영화 목록 테스트는 `test/movie/`에 있다.
