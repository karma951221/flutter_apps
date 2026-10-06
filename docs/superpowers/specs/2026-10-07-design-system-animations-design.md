# 공통 위젯 애니메이션 — 설계

> [진행 현황](../../status.md) · 대상 패키지 `packages/design_system`

## 1. 목적

공통 위젯에 **선택적(opt-in)** 애니메이션 인자를 더한다. 기본값은 모두 "끔"이라
기존 호출부의 모양·동작·테스트는 바뀌지 않는다. 호출부를 실제로 켜는 일은 이 작업
범위 밖이다 — 위젯이 준비되면 화면별로 켠다.

## 2. 사용 현황과 선정

`apps/*/lib` + `packages/features` 의 호출 수(2026-10-07)와 판정.

| 위젯 | 호출 | 판정 | 애니메이션 |
|---|---|---|---|
| `AppCountAction` | 2 (좋아요·반응) | **적용** | 개수 바뀔 때 숫자 세로 슬라이드(증가는 위로, 감소는 아래로) · `isActive` 가 켜질 때 아이콘 탄성 스케일 · 색 전환 |
| `AppButton` | 50 | **적용** | 라벨 ↔ 로딩 스피너 크로스페이드 + 스케일 |
| `AppPlaceholder` | 47 | **적용** | 처음 나타날 때 페이드 + 살짝 위로 슬라이드 |
| `AppListFooter` | 4 | **적용** | 로딩 스피너 / 끝 안내 / 빈 칸 사이 크로스페이드(높이도 부드럽게) |
| `AppAvatar` | 12 | **적용** | 이미지가 로드되면 이니셜 위로 페이드인 |
| `AppListTile` | 31 | 보류 | 진입 스태거는 `ListView.builder` 재활용 때마다 다시 재생돼 스크롤을 어지럽힌다 |
| `AppSnackBar` · `AppConfirmDialog` · `AppOverflowMenu` | — | 제외 | Material 이 이미 등장 전환을 그린다 |
| `AppLoadMoreListener` | — | 제외 | 그리지 않는다 |

## 3. API

### 3.1 모션 토큰 — `AppMotion` (`lib/src/theme/app_motion.dart`)

CLAUDE.md 규칙 5(시각 토큰 하드코딩 금지)에 맞춰 시간·곡선도 토큰으로 둔다.

```dart
abstract final class AppMotion {
  static const short = Duration(milliseconds: 150);   // 색·작은 전환
  static const medium = Duration(milliseconds: 250);  // 콘텐츠 교체
  static const long = Duration(milliseconds: 400);    // 등장
  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutBack;       // 탄성(좋아요 아이콘)

  /// 시스템 '애니메이션 줄이기'가 켜져 있으면 false.
  static bool enabled(BuildContext context) => !MediaQuery.of(context).disableAnimations;
}
```

### 3.2 위젯별 인자

모든 인자는 이름 있는 선택 인자, 기본 `false`. 켜져 있어도 `AppMotion.enabled` 가
`false` 면 애니메이션 없이 최종 상태만 그린다.

| 위젯 | 인자 |
|---|---|
| `AppCountAction` | `bool animate = false` |
| `AppButton` (primary · secondary) | `bool animateLoading = false` — `text` 는 로딩이 없어 받지 않는다 |
| `AppPlaceholder` | `bool animateIn = false` |
| `AppListFooter` | `bool animate = false` |
| `AppAvatar` | `bool fadeInImage = false` |

Duration 인자는 두지 않는다 — 화면마다 시간을 고르면 곧 어긋난다. 바꿔야 하면
`AppMotion` 토큰을 고친다.

## 4. 구현 메모

- `AppCountAction`: `animate` 면 숫자를 `AnimatedSwitcher`(키 = count, 방향은 이전
  값과 비교)로, 아이콘은 `isActive` false→true 때 `AppMotion.emphasized` 로
  1.0→1.25→1.0, 색은 `TweenAnimationBuilder<Color?>`. 상태가 필요하면
  `StatefulWidget` 으로 바꾸되 공개 생성자는 그대로.
- `AppButton`: `AnimatedSwitcher` + `FadeTransition`·`ScaleTransition`. 버튼 폭이
  흔들리지 않게 `layoutBuilder` 는 `Stack(alignment: center)`.
- `AppPlaceholder`: 마운트 때 한 번만 재생(`TweenAnimationBuilder`). 다시 빌드돼도
  재생하지 않는다.
- `AppListFooter`: `AnimatedSize` + `AnimatedSwitcher`, 세 상태에 각자 키.
- `AppAvatar`: `CircleAvatar.foregroundImage` 대신 `ClipOval` + `Image(frameBuilder)`
  로 첫 프레임에 `AnimatedOpacity`. 동기 로드(`wasSynchronouslyLoaded`)면 페이드
  없이 바로. 꺼져 있으면 기존 코드 경로 그대로.

## 5. 완료 조건

- 위젯마다 테스트: (a) 기본값에서 기존 트리 그대로, (b) 켰을 때 전환 위젯이
  존재하고 `pumpAndSettle` 후 최종 상태, (c) `disableAnimations: true` 면 전환 없이
  최종 상태.
- `packages/design_system` 에서 `flutter analyze` · `flutter test` 통과, 앱 쪽
  기존 테스트에 영향 없음.
- `design_system.dart` 가 `AppMotion` 을 내보낸다. CLAUDE.md "현재 공통 진입점"에
  애니메이션 인자 한 줄 추가.
