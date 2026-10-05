# 디자인 시스템 적용 — 테스트

> [테스트 가이드](../../../../../docs/testing/README.md) · [pawlog 허브](../../README.md) · [디자인 시스템](../../design.md) · [계획](plan.md) · [구현 기록](history.md)

```bash
cd apps/pawlog && flutter test test/presentation/theme test/presentation/common
cd apps/pawlog && flutter test test/presentation/feed test/presentation/tracking test/presentation/walk test/presentation/dog
cd packages/core && flutter test test/media/image_picker_service_test.dart   # P5
cd apps/pawlog && flutter test            # 전체
```

## `test/presentation/theme/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `pawlog_theme_test.dart` (11) | `PawlogTheme` · `PawlogColors` · `PawlogTextStyles` · `PawlogMotion` | 라이트 바탕 · 주 색 · 오류색 · 다크 바탕 · 다크 주 색 · 연두는 모드 공통 · 연두가 `ColorScheme` 에 없음 · 입력 테두리가 `rule` 이 아니고 바탕 · 시트와 3:1 초과(P4) · 제목 고운돋움 · 본문 Pretendard · 메모 개구 · 숫자 700 + `tabularFigures` · 모서리 4 · 12 · 20 · 알약, 주 버튼 58 · 칩 체크 없음 · 선택 바탕(P2) · 간격 토큰 · 확장이 없을 때 밝기별 기본값 · `disableAnimations` → `off` |

## `test/presentation/common/`

| 파일 | 대상 | 확인 |
|---|---|---|
| `widget/pawlog_primary_button_test.dart` (6) | `PawlogPrimaryButton` · `PawlogBottomAction` | 높이 58 · 남색 · 탭 → `onPressed` · 누르는 동안 `0.97` 에서 떼면 `1` · `onPressed: null` → 투명도 `0.4` 이고 눌러도 줄지 않음 · 로딩 전환 중(100ms)엔 라벨과 진행 표시가 함께 있고 200ms 뒤 진행 표시만, 투명도 `1`, 탭 무시 · `disableAnimations` 면 다음 프레임에 전환 끝 · `.stop` 은 먹색 |

기존 테스트에서 바꾼 것: `active_walk_page_test` 의 시작 버튼 활성 판단을 `AppButton` 에서
`PawlogPrimaryButton` 으로.

## `test/presentation/feed/page/`

| 파일 | 대상 | 바뀐 것 |
|---|---|---|
| `walk_feed_page_test.dart` (12 → 13) | `WalkFeedPage` · `WalkFeedEntry` | 빈 피드: 항목 없음 + 하단 `walk-feed-start-button` → `onStartWalk` · 추적 중 · 저장 전 빈 피드엔 시작 버튼 없음 · 항목: `Card` 없음, 달 머리 `2026년 10월` · 일 `3` · 요일 `토` · 이름 `콩이1` · 시각 `09:00` · `1.2 km` · `30분` · 메모 · **새 테스트 — 같은 날 두 기록 + 전날 하나: 첫 기록만 `walk-feed-date-*`, `showDate` / `continuesBelow` 가 (참, 참) · (거짓, 거짓) · (참, —), 달 머리 하나** · 키 `walk-feed-card-*` → `walk-feed-entry-*`, `walk-feed-fab` → `walk-feed-start-button` |

날짜 묶음 테스트는 세 항목이 한 화면에 들어오도록 `tester.view` 를 400×2400 으로 둔다 — 4:3 사진 칸
때문에 기본 800×600 에서는 둘째 항목부터 지연 생성돼 위젯을 찾을 수 없다.

## 4단계 — 배너 · 진행 화면 · 경로 선

| 파일 | 대상 | 확인 |
|---|---|---|
| `tracking/widget/active_walk_banner_test.dart` (4, 새 파일) | `ActiveWalkBanner` · `PulseDot` | 추적 중: 남색 · 모서리 12 · 연두 점 · `12:05` · 저장 전: 점 · 시간 없음 · 점은 0.8초에 0.5 미만으로 옅어졌다 1.6초에 1 로 · `disableAnimations` 면 멈춘 채 1, 돌아가는 애니메이션 없음 |
| `tracking/page/active_walk_page_test.dart` (+1, 1건 보강) | `ActiveWalkPage` | **P1** 반려견 선택 화면 제목 "산책 준비", "산책 중" 없음 · 추적 중: 제목 "산책 중", 끝내기 버튼이 `walk-active-sheet` 안, 경과 시간 글자 44, 끝내기 `isStop` |
| `walk/widget/route_map_test.dart` (+1) | `RouteMap` | 폴리라인 연두 · 5, 테두리 남색 · 합 9, 둥근 끝 |
| `feed/widget/route_preview_painter_test.dart` (4 → 5) | `RoutePreviewPainter` | 테두리 색이 있으면 9 남색 `path` 다음 5 선 `path` · `shouldRepaint` 가 테두리 색도 비교 |

기존 테스트에서 바꾼 것: 피드 테스트 중 추적 중 배너가 뜨는 두 건은 `pumpApp(disableAnimations: true)`
(점멸이 끝나지 않아 `pumpAndSettle` 이 시간 초과).

## 5단계 — 저장 · 상세 · 반려견

| 파일 | 대상 | 확인 |
|---|---|---|
| `dog/page/dog_edit_page_test.dart` (1건 교체 + 1) | `DogEditPage` | **P3** 이름 누락 → 이름 입력칸 `errorText` "반려견 이름을 입력해 주세요", `SnackBar` 없음, 이름을 고치면 `errorText` 없음 · 이름 외 실패(`unknown`) → `SnackBar` |
| `dog/widget/dog_chips_test.dart` (1, 새 파일) | `DogChips` | **P2** 선택 · 해제 상태, `showCheckmark: false`, 체크 아이콘 없음 |
| `dog/widget/dog_avatars_test.dart` (+1) | `DogAvatars` | 두 마리 크기 52×32(지름 32, 겹침 12), 테두리 `paper` 2 |
| `dog/page/dog_list_page_test.dart` | `DogListPage` | 키 `walk-dog-add-fab` → `walk-dog-add-button`(빈 상태의 "반려견 추가" 탭은 하단 버튼이 받는다) |
| `walk/page/walk_edit_page_test.dart` (+1) | `WalkEditPage` | 신규 폼에 `walk-edit-route`, 메모 입력 글꼴 개구 |
| `walk/page/walk_detail_page_test.dart` (+1) | `WalkDetailPage` | 메모 글자 모양 = `PawlogTextStyles.memo`, 사진 4:3 · 모서리 4 |
| `packages/core` `test/media/image_picker_service_test.dart` (2, 새 파일) | `ImagePickerService.captureImage` | 취소 → null · **P5** 준비(디코드)가 실패해도 카메라 원본 파일이 지워진다 |

성공 경로(압축 성공 뒤 삭제)는 `flutter_image_compress` 플러그인이 테스트에서 돌지 않아 단위 테스트로
덮지 못했다 — 삭제가 `finally` 에 있어 두 경로가 같은 줄을 지난다.

## 6단계 — 경로 그리기 모션

| 파일 | 대상 | 확인 |
|---|---|---|
| `walk/widget/route_draw_test.dart` (7, 새 파일) | `RouteDraw` · `RouteSketch` · `RouteMap` | `partialRoute` 0 → 출발점만 · 1 → 전체 · 0.5 · 0.25 에서 마지막 구간을 길이 비율로 끊음 · `RouteSketch(animate)` 진행값 0 → 0.8초에 0~1 사이 → 1.6초에 1 · **애니메이션 줄이기면 처음부터 1, 돌아가는 애니메이션 없음** · `animate: false`(피드) 1 · `RouteMap(animateDraw)` 첫 프레임 선은 출발점 하나 · 도착 점 없음 → 1.6초 뒤 전체 점 · 점 2개 · **줄이기면 처음부터 전체** |

연출 테스트는 `pumpApp` 을 쓰지 않는다 — `pumpAndSettle` 이 1.6초를 끝까지 흘려 시작 상태를 볼 수 없다.

## 에뮬레이터 QA 후속 (2026-10-05)

| 파일 | 대상 | 확인 |
|---|---|---|
| `tracking/page/active_walk_page_test.dart` (+1) | `ActiveWalkPage` | **Q1** 추적 중 `SimpleAttributionWidget` · "OpenStreetMap contributors" 가 있고 글자 띠 아래 끝 ≤ `walk-active-sheet` 위 끝 |
| `walk/page/walk_detail_page_test.dart` (+1) | `WalkDetailPage` | **Q1** 출처 글자 띠가 `walk-detail-map` 안에 있다 |
| `walk/widget/route_sketch_test.dart` (2, 새 파일) | `RouteSketch` · `RoutePreviewPainter` | **Q2** 400×300 상자에서 가로로 긴 경로: 좌우 끝이 여백 24.5(20 + 테두리 반 폭)에 닿고 경계 중심이 상자 중심 · 세로로 긴 경로: 위아래 끝이 여백에 닿고 중심이 상자 중심 |
| `walk/format/walk_format_test.dart` (+3) | `WalkFormat.duration` | **Q3** 58초 · 0초 → `1분 미만`, 60초 → `1분` · 60분 → `1시간`, 2시간 30초 → `2시간` · en `< 1 min` · `1 h`, ja `1分未満` · `1時間` |
| `dog/page/dog_edit_page_test.dart` (+4) | `DogEditPage` | **Q4** 사진 변경 → 출처 시트(앨범 · 카메라) · 카메라 → `captureImage` · 앨범 → `pickImage` · 닫기 → 호출 없음 · 카메라로 찍고 저장 없이 나가면 새 파일 삭제 |

## 에뮬레이터

**2026-10-05 실행** — Android 17 에뮬레이터, 라이트 · 다크. 찾은 네 가지(Q1~Q4)는 이번에 고쳤다
([구현 기록](history.md#에뮬레이터-qa-후속-2026-10-05)).

| # | 시나리오 | 결과 |
|---|---|---|
| ① | 스플래시 · 앱 아이콘 남색 + 연두 | **PASS** |
| ② | P1 시작 전 진행 화면 제목 "산책 준비" | **PASS** |
| ③ | P2 강아지 칩 — 체크 없이 상태로 선택 표시 | **PASS** |
| ④ | P3 반려견 이름 누락이 입력칸 아래 오류로 | **PASS** |
| ⑤ | P4 다크 입력칸 테두리 | **PASS** |
| ⑥ | P5 카메라로 찍은 뒤 `cache/` 에 원본 없음 | **PASS** |
| ⑦ | 피드 타임라인 — 달 머리 · 날짜 열 · 리드줄 | **PASS** |
| ⑧ | 진행 배너 남색 + 연두 점 | **PASS** |
| ⑨ | 진행 화면 시트 — 44 숫자 · 먹색 끝내기 버튼 | **PASS** |
| ⑩ | 경로 선 남색 테두리 + 연두 | **PASS** |
| ⑪ | 저장 폼 진입 시 경로 1.6초 그리기 | **PASS** |
| ⑫ | 메모 개구 · 상세 사진 4:3 | **PASS** |
| ⑬ | 다크 — 피드 · 상세 · 반려견 편집 | **PASS** |
| Q1 | 진행 화면 시트가 지도 OSM 출처 표시를 가림 | **FAIL → 수정** — 지도를 시트 위 끝 + 모서리까지만, 출처를 그만큼 올림 |
| Q2 | 저장 폼 경로 그림이 상자 위에 붙고 여백이 없어 보임 | **FAIL → 수정** — 여백 20 + 테두리 반 폭, 두 축 가운데 |
| Q3 | 58초 산책이 피드에 "0분" | **FAIL → 수정** — "1분 미만" |
| Q4 | 반려견 "사진 변경" 에 카메라 선택지 없음 | **FAIL → 수정** — 산책과 같은 출처 시트 |

Q1~Q4 수정 뒤의 화면은 에뮬레이터에서 다시 보지 않았다 — 위젯 테스트로만 확인했다. 접근성 '애니메이션
삭제' 를 켠 경로 그리기는 위젯 테스트(`route_draw_test`)로만 확인했다.
