# 디자인 시스템 적용 — 계획 (범위 · 단계 · 완료 조건)

> [pawlog 허브](../../README.md) · [디자인 시스템](../../design.md) · [구현 기록](history.md) · [테스트](testing.md)

> 상태: 착수 2026-10-05 · 진행 상태의 단일 기준은 [진행 현황](../../status.md)

## 범위

[design.md](../../design.md)(2026-10-04, `/design-consultation`)를 pawlog 화면 전체에 적용한다.
지금 앱은 공용 `AppTheme`(M3 `fromSeed` 남색 기본값)을 그대로 쓴다. design.md 가 기준 문서이고,
이 계획은 **순서와 완료 조건**만 정한다. 값(색 · 서체 · 크기 · 모서리 · 모션)은 design.md 에서 읽는다.

함께 처리하는 에뮬레이터 QA(2026-10-04) 다듬기 항목:

| # | 항목 | 처리 |
|---|---|---|
| P1 | 시작 전 진행 화면 제목이 "산책 중" | 시작 전에는 "산책 준비" 등 상태에 맞는 제목 |
| P2 | 강아지 칩의 선택 체크가 아바타 글자와 겹침 | 체크는 칩 상태(테두리 · 바탕)로만 표시하고 아바타는 그대로 |
| P3 | 반려견 이름 검증이 스낵바뿐이라 키보드 위에서 저장 버튼을 가림 | 입력칸 `errorText` 로 표시 |
| P4 | 다크 모드 입력칸 테두리 대비가 낮음 | 테마 토큰(`rule` / `dark-rule` 보다 진한 입력 테두리)으로 해결 |
| P5 | 카메라 원본이 `cache/` 에 남음 | 저장소로 복사한 뒤 picker 임시 파일 삭제 |

## 경계

- **pawlog 전용 테마는 앱 안에 둔다** — `apps/pawlog/lib/presentation/theme/`
  (walk 의 `presentation/theme/walk_theme.dart` 선례). `packages/design_system` 의 공용 위젯
  (`AppButton` · `AppPlaceholder` · `AppConfirmDialog` · `AppAvatar` …)은 계속 쓰고, 모양은
  pawlog `ThemeData`(colorScheme · textTheme · 컴포넌트 테마)와 `ThemeExtension` 으로 바꾼다.
  공용 위젯으로 표현 못 하는 것만 feature 전용 위젯으로 감싼다(루트 CLAUDE.md UI 규칙).
- 화면에 `Colors.*` · 숫자 여백 · `BorderRadius.circular(n)` 을 직접 적지 않는다. pawlog 토큰
  (`PawlogColors` · `PawlogSpacing` · `PawlogRadius` · `PawlogMotion` 같은 이름)을 만든다.
- 서체는 `apps/pawlog/assets/fonts/`(OFL 라이선스 파일 포함)에 번들돼 있다.
- 다른 앱(trader · commute · walk)은 건드리지 않는다.

## 단계 (커밋 단위)

1. **토큰 · 테마 · 서체** — 색(라이트 · 다크), 서체 등록(pubspec `fonts:`), textTheme
   (display · title = 고운돋움, 본문 · 숫자 = Pretendard, 숫자는 `FontFeature.tabularFigures()`),
   모서리 · 간격 · 모션 토큰, 입력 · 버튼 · 앱바 · 다이얼로그 · 시트 컴포넌트 테마. `app.dart` 가
   pawlog 테마를 쓴다. → P4 해결
2. **주 버튼** — 하단 고정 알약 58, 남색, 누름 0.97 축소, 비활성 0.4, 로딩 크로스페이드,
   산책 끝내기는 먹색 변형. 화면마다 주 버튼 하나.
3. **피드 타임라인** — 카드 제거, 날짜 열(일 30/700 · 요일) + 리드줄 1.5px + 본문 열(아바타 · 이름 ·
   시각 → 사진 4:3 또는 경로 썸네일 → 거리 · 시간 → 메모). 같은 날은 날짜 한 번. 빈 상태는
   수첩 첫 장 같은 한 줄 + 시작 버튼(추적 중 안내는 기존 동작 유지).
4. **진행 배너 · 산책 중 화면** — 배너 남색 + 연두 점 1.6초 점멸 + 경과 시간. 진행 화면은 지도 위
   20 둥근 시트에 거리 · 시간 44. 경로 선은 남색 casing 9 위 연두 5(지도 · 썸네일 공통).
   → P1 해결
5. **저장 · 상세 · 반려견 화면** — 메모는 개구 20(빈 메모는 자리 없음), 사진 모서리 4, 아바타 겹침
   -12 + 바탕색 2px 테두리, 칩 선택 표시. → P2 · P3 · P5 해결
6. **경로 그리기 모션** — 저장 화면 진입 · 상세 열 때 경로가 1.6초에 걸쳐 그려진다.
   `MediaQuery.disableAnimations` 면 바로 완성.

## 완료 조건

- `flutter analyze` 0건, `flutter test` 통과(기존 205 + 새 테스트). 테마 토큰 · 주 버튼 · 피드 날짜 묶음 ·
  경로 애니메이션 끄기 분기에 위젯 테스트가 있다
- 화면 코드에 하드코딩 색 · 숫자 여백이 없다
- `flutter build apk --debug` 성공, 라이트 · 다크 에뮬레이터 확인([테스트](testing.md))
- design.md Decisions Log 와 어긋나게 구현한 것이 있으면 이 폴더 `history.md` 에 이유를 적는다
