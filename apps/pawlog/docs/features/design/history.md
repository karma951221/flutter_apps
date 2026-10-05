# 디자인 시스템 적용 — 구현 기록

> [pawlog 허브](../../README.md) · [디자인 시스템](../../design.md) · [계획](plan.md) · [테스트](testing.md)

설계 판단 · [design.md](../../design.md) 와 다르게 간 것 · 검증 결과를 남긴다. 진행 상태는
[진행 현황](../../status.md)에만 적는다. 단계 번호는 [계획](plan.md#단계-커밋-단위)의 1~6 이다.

## 1 — 토큰 · 테마 · 서체

### 테마는 `lib/presentation/theme/` — 공용 `AppTheme` 을 쓰지 않는다

walk 의 `WalkTheme` 은 `AppTheme.light(seedColor:)` 에 씨앗색만 바꾼다. pawlog 는 `fromSeed` 가
만드는 M3 톤(보라빛 컨테이너 · 틴트)을 벗는 것이 목적이라 `ColorScheme` 을 역할마다 직접 채웠다.
`AppButton` · `AppPlaceholder` · `AppConfirmDialog` · `AppAvatar` · `AppListTile` 은 그대로 쓰고,
모양은 `PawlogTheme` 의 컴포넌트 테마(버튼 · 입력 · 칩 · 다이얼로그 · 시트 · 스낵바 · 앱바)로 바꾼다.

| 파일 | 내용 |
|---|---|
| `pawlog_colors.dart` | `PawlogColors`(`ThemeExtension`) — design.md 색 + 파생 토큰 `inputBorder` · `routeCasing` · `stop` · `shadow` |
| `pawlog_typography.dart` | `PawlogFonts` · `PawlogTypography.textTheme` · `PawlogTextStyles`(`ThemeExtension`: `numberHero` · `number` · `memo` · `dogName` · `feedDay` · `feedWeekday`) |
| `pawlog_spacing.dart` | `PawlogSpacing`(4 · 8 · 14 · 20 · 28 · 48) · `PawlogSize`(날짜 열 48 · 리드줄 1.5 · 주 버튼 58 · 경로 5/9 · 아바타 …) |
| `pawlog_radius.dart` | `PawlogRadius` 사진 4 · 입력 12 · 시트 20 · 알약 |
| `pawlog_motion.dart` | `PawlogMotion` 120 · 200 · 300 · 1600ms, enter · exit · move 곡선, `off(context)` |
| `pawlog_elevation.dart` | `PawlogShadows` — 주 버튼 · 지도 위 시트 두 곳 |
| `pawlog_theme.dart` | `PawlogTheme.light()` · `dark()`, 위 파일 export |

`ColorScheme` 매핑에서 정한 것:

- `primaryContainer` · `secondaryContainer` = `rule`. `AppAvatar` 이니셜 바탕과 `+n` 원이 이 색을
  쓴다 — 세 번째 색을 만들지 않으려고 중립색 위에 남색 글자로 했다
- `surfaceContainer*` = `sheet`(다이얼로그 · 시트 · 메뉴가 한 단계 올라온 면), `Highest` 만 `mapBg`
  (썸네일 대체 바탕)
- `tertiary` = `primary`. 연두(`accent`)는 `ColorScheme` 어디에도 넣지 않았다 — 공용 위젯이 연두를
  버튼 · 배경으로 집어 쓰는 길을 막는다(테스트가 지킨다)

### design.md 에 없는 값 — 보수적으로 정한 것

| 토큰 | 값 | 이유 |
|---|---|---|
| `inputBorder` 라이트 · 다크 | `#8A877D` · `#73746A` | QA P4. `rule`(`#DDDAD1` · `#3A3B35`)은 바탕과 1.3:1 남짓이라 입력칸 경계가 안 보였다. WCAG 비텍스트 3:1 을 넘는 가장 옅은 회갈로 골랐다 |
| `error` 다크 | `#E0705C` | design.md 는 `error` 하나뿐이다. `#B3402E` 는 `dark-paper` 위 3.3:1 이라 안내 글자로 약해 같은 계열을 밝혔다 |
| `mapBg` · `mapPark` 다크 | `dark-sheet` · `#2C3328` | 다크 지도 바탕이 정의돼 있지 않다. 썸네일 자리는 시트와 같은 면으로 뒀다 |
| `routeCasing` | 모드와 상관없이 `#2C3B57` | design.md 는 `casingColor: {colors.primary}` 지만, OSM 타일은 다크에서도 밝은 지도라 다크 `primary`(`#A9B8D6`)로는 연두 선의 테두리 구실을 못 한다 |
| `stop` · `onStop` 다크 | `dark-text` · `dark-paper` | '먹색' 버튼을 다크에서 반전 — 먹색 바탕 위 먹색 버튼은 보이지 않는다 |
| 서체 크기 중 design.md 에 없는 자리 | `titleMedium` 16/500 · `bodyMedium` 14 · `labelLarge` 16/700(버튼) · `dogName` 고운돋움 17 | 토큰 7개로 Material `TextTheme` 15칸을 모두 채울 수 없어 가까운 토큰에서 크기만 옮겼다 |

### 서체 번들

`assets/fonts/` 에 고운돋움 · 개구(Google Fonts, OFL) · Pretendard 400/500/700(orioncactus, OFL)과
`OFL-*.txt` 를 함께 두고 `pubspec.yaml` `fonts:` 에 등록했다. 일본어 글리프는 세 서체 모두 없거나
일부라 시스템 폰트로 대체된다(design.md Typography 그대로).

## 2 — 주 버튼

### `PawlogPrimaryButton` 은 `FilledButton` 을 직접 쓴다 — `AppButton.primary` 를 감싸지 않은 이유

루트 CLAUDE.md 는 공용 위젯을 감싸라고 한다. `AppButton` 은 라벨이 `String` 이고 로딩이면 자식을
즉시 스피너로 바꾼다. 버튼을 통째로 `AnimatedSwitcher` 에 넣으면 두 버튼의 남색 바탕이 겹쳐 페이드되며
중간에 바탕이 75% 까지 옅어진다. 바탕은 그대로 두고 안쪽만 200ms 크로스페이드하려면 자식을 직접 쥐어야
했다. 모양(알약 · 58 · 색 · 글자)은 `filledButtonTheme` 에서 오므로 `AppButton.primary` 와 같다.
재사용 범위가 pawlog 하나라 `design_system` 으로 승격하지 않았다(`lib/presentation/common/widget/`).

- 누름 0.97 · 120ms ease-out(`Listener` + `AnimatedScale`), 비활성 투명도 0.4(`AnimatedOpacity`),
  로딩은 흐리지 않는다 — 로딩은 '기다림' 이지 '못 누름' 이 아니다
- 테마의 `filledButtonTheme` 는 비활성 색을 따로 두지 않는다. 흐림은 이 위젯 한 곳에서만 일어난다
- `.stop` — 먹색(`stop` · `onStop`) 변형, 산책 끝내기
- 그림자는 design.md Elevation 대로 아래 6 · 블러 16. `MediaQuery.disableAnimations` 면 모든 전환이 0ms

### 하단 고정은 `bottomNavigationBar` 가 아니라 본문 `Column` 끝

`PawlogBottomAction` 이 좌우 20 · 아래 안전 영역을 둔다. `Scaffold.bottomNavigationBar` 는 키보드
뒤에 남아 가려진다. 본문 `Column(Expanded(목록), PawlogBottomAction)` 이면 본문과 함께 키보드 위로
올라온다 — 반려견 이름 입력 중 저장 버튼이 가려지던 QA P3 의 절반이 여기서 풀린다.

적용: 진행 화면 시작 · 끝내기(`.stop`), 저장 폼 저장, 반려견 편집 저장. 저장 폼의 버리기는 목록 끝의
텍스트 버튼으로 남겼다(design.md "다른 동작은 앱바나 줄글 안의 텍스트 버튼"). 피드 시작 버튼은 3단계,
반려견 목록의 추가 버튼은 5단계에서 바꾼다.
