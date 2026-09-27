# 테스트 가이드

> [문서 허브](../README.md) · [아키텍처](../architecture.md) · [개발환경](../setup.md) · [E2E](../../apps/trader/docs/e2e.md) · [컨벤션 검사](conventions.md)

테스트는 구현 코드의 구조를 그대로 반영한다. feature 테스트는 반드시
`app/test/features/<feature>/`에 두고, 해당 구현은
`app/lib/features/<feature>/`에서 찾는다.

```text
app/lib/                         app/test/
├── core/                 →      ├── core/
├── features/
│   ├── auth/             →      ├── features/auth/
│   ├── feed/             →      ├── features/feed/
│   ├── post/             →      ├── features/post/
│   ├── profile/          →      ├── features/profile/
│   ├── reaction/         →      ├── features/reaction/
│   ├── comment/          →      ├── features/comment/
│   ├── safety/           →      ├── features/safety/
│   ├── chat/             →      ├── features/chat/
│   ├── preferences/      →      ├── features/preferences/
│   ├── home/             →      ├── features/home/
│   └── settings/         →      └── features/settings/
└── …                     →      └── convention/  # 코드베이스 전체 규칙
```

공통·교차 관심사 검사는 `test/core/`, `test/design_system/`, `test/convention/`에
둔다. 특정 feature의 테스트를 공통 디렉터리에 두지 않는다.

feature 표에 들어가지 않는 공용 검사는 아래에 있다. 여기 있는 것을 바꾸면 여러
화면이 한꺼번에 영향을 받으므로, feature 문서가 아니라 이 표를 갱신한다.

| 파일 | 검증 |
|---|---|
| `core/data/nickname_match_test.dart` | 닉네임 매칭 — LIKE 메타문자 이스케이프, `lower()` 기준 비교 ([근거](../../apps/trader/docs/audits/audit-2026-08-27.md)) |
| `core/data/mapper/supabase_error_mapper_test.dart` | DB 제약·트리거 문구 → 사용자 fallback + `FailureCode` 변환 |
| `core/extension/date_time_format_test.dart` | 날짜 표기 세 종류(연도 포함·생략·시각), 로컬 시각 변환, ko·en·ja locale |
| `core/l10n/failure_localizations_test.dart` | 오류 code 번역 · 미매핑 서버 원문 · 종류별 기본 문구 fallback |
| `design_system/widget/app_confirm_dialog_test.dart` | 취소 라벨이 언어를 따른다 · destructive 색 · 확인/취소/바깥 탭 결과 |
| `design_system/widget/app_placeholder_test.dart` | 아이콘·설명·행동 버튼이 있을 때만 그린다 |
| `design_system/widget/app_overflow_menu_test.dart` | 빈 항목이면 안 그린다 · destructive 색 · 비활성 |
| `design_system/widget/app_load_more_listener_test.dart` | 최상위 세로 목록의 끝만 감지하고 가로·중첩 스크롤은 무시 |
| `design_system/widget/app_list_footer_test.dart` | 추가 로딩·다음 페이지·목록 끝 세 상태 |
| `design_system/theme/app_theme_contrast_test.dart` | 두 테마의 `colorScheme` 파생색이 WCAG AA(4.5:1)를 넘는다 |
| `convention/arb_description_convention_test.dart` | gen-l10n 템플릿(`app_ko.arb`)의 모든 키가 `@key` description 을 가진다 |
| `convention/trigger_message_mapping_test.dart` | 마이그레이션의 한국어 `raise` 문구를 `SupabaseErrorMapper` 가 모두 안다 |

## 실행

```bash
cd app
flutter test                 # 전체 테스트
flutter analyze              # 정적 분석
flutter test test/features/post
flutter test test/convention
```

E2E는 에뮬레이터와 로컬 Supabase가 필요하므로 별도로 돈다. [E2E 테스트](../../apps/trader/docs/e2e.md) 참고.

```bash
cd app
patrol test
```

## 테스트 수준

- **scenario**: 입력 정규화, 정책, 저장소 호출 조합을 mock repository로 검증한다.
- **repository/mapper**: DTO와 domain 변환, `Failure`/`Result` 경계 처리를 검증한다.
- **presentation**: Bloc/Cubit은 UseCase facade를 mock하고 상태 전이를 검증한다.
- **Supabase query/RLS**: fluent query의 세부 조립은 mock보다 로컬 Supabase 통합
  테스트로 검증한다.
- **E2E**: 라우터 리다이렉트, 세션 유지, 화면 간 값 전달처럼 mock으로는 확인되지
  않는 연결을 실제 앱·실제 Supabase로 검증한다. `app/patrol_test/`에 둔다.

## Feature별 범위

feature 테스트 문서(각 feature 폴더의 `testing.md`)는 **대상 · 시나리오 · 기대 결과** 표 형식으로 통일한다. 테스트를
추가·변경하면 해당 문서의 표를 같은 커밋에서 갱신한다.

- [auth](../../apps/trader/docs/features/auth/testing.md)
- [profile](../../apps/trader/docs/features/profile/testing.md)
- [post](../../apps/trader/docs/features/post/testing.md)
- [feed](../../apps/trader/docs/features/feed/testing.md)
- [reaction](../../apps/trader/docs/features/reaction/testing.md)
- [comment](../../apps/trader/docs/features/comment/testing.md)
- [safety](../../apps/trader/docs/features/safety/testing.md)
- [follow](../../apps/trader/docs/features/follow/testing.md)
- [chat](../../apps/trader/docs/features/chat/testing.md)
- [settings](../../apps/trader/docs/features/settings/testing.md)
- [preferences](../../apps/trader/docs/features/preferences/testing.md)
- [trade](../../apps/trader/docs/features/trade/testing.md)
- [commute](../../apps/commute/docs/testing.md) — 둘째 앱. `packages/features/commute` 와 `apps/commute` 에서 각각 돈다
- [검수 기록 (2026-08-24)](../../apps/trader/docs/audits/audit-2026-08-24.md)
- [검수 기록 (2026-08-27)](../../apps/trader/docs/audits/audit-2026-08-27.md)
- [코드 컨벤션 검사](conventions.md)
- [E2E 테스트 (Patrol)](../../apps/trader/docs/e2e.md)
