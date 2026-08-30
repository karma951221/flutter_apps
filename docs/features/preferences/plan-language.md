# preferences — 계획 (다국어)

> [문서 허브](../../README.md) · [아키텍처](../../architecture.md) · [테마 계획](plan-theme.md) · [설정 계획](../settings/plan.md)

> 상태: **완료** · 작성 2026-08-26 · 완료 2026-08-30
> 진행 상태의 단일 기준은 [진행 현황](../../status.md)이다.

## 범위

앱 언어를 사용자가 고르고(시스템 · 한국어 · 영어 · 일본어), 선택이
`shared_preferences` 에 남는다. **화면 문자열뿐 아니라 오류·검증 문구까지 이번에
전부 번역한다** (사용자 확정 2026-08-26). 예외는 하나 — 매핑되지 않은 서버 원문
(예상 못 한 오류의 raw 메시지)은 어쩔 수 없이 원문 그대로 뜬다.

사전 조사(2026-08-26): 한국어 문자열이 55개 파일에 289건. 성격이 셋으로 갈리고
셋의 처리 방식이 다르다.

| 분류 | 규모 | 처리 |
|---|---|---|
| 화면 문자열 (presentation) | ~245건 | gen-l10n ARB 추출 |
| 검증·오류 문구 (core·domain·data) | ~44건 + domain scenario | **코드화** — 문자열 대신 키를 돌려주고 presentation 이 번역 |
| DB 가 던지는 한국어 (트리거 문구) | 조사 시점 7건 · 현재 11건 | **매칭 키는 한국어 유지**, 표시만 번역 — mapper 가 이미 정확 문자열 매칭으로 식별하므로 그 자리가 번역 지점 |

## 확정한 결정과 근거

| 항목 | 결정 | 근거 |
|---|---|---|
| 선택지 | **4옵션** — 시스템 · 한국어 · 영어 · 일본어 (사용자 확정) | 테마의 3상태와 같은 구조. 기본값 시스템이면 기기 언어가 일본어인 사용자가 설치 직후 일본어로 만난다. 미지원 언어 기기는 영어 fallback |
| 오류 범위 | **전부 이번에** (사용자 확정) | 화면은 영어인데 오류만 한국어로 뜨는 반쪽 상태를 만들지 않는다. 태스크를 나눠 순차 진행하되 한 번에 끝낸다 |
| feature 개명 | **`features/theme` → `features/preferences`** | [테마 계획](plan-theme.md)에 기록한 개명 기준("두 번째 로컬 설정이 기획에 실리는 시점")이 지금 발동한다. 저장소는 관심사별(`ThemeRepository` · `LanguageRepository`) 유지, facade 만 `PreferencesUseCase` 로 통합 (규칙 ③) |
| i18n 도구 | **Flutter 표준 gen-l10n** (`flutter_localizations` + ARB) | 서드파티 없이 빌드에 통합되고, ARB 가 표준 포맷이라 번역 파일이 도구 독립적이다 |
| ARB 기준 언어 | **한국어** (`app_ko.arb` 가 template) | 원문이 한국어다. 영어를 template 로 두면 ko→en→ko 이중 번역이 생긴다. 미번역 키는 gen-l10n 이 빌드에서 잡는다 |
| 저장 형식 | 키 `language`, 값 `'system'` · `'ko'` · `'en'` · `'ja'` | `theme_mode` 와 같은 방식. 모르는 값·없는 값은 시스템 |
| domain 타입 | **자체 enum `AppLanguage`** | `AppThemeMode` 와 같은 결. `Locale` 은 presentation 만 안다 |
| 상태 관리 | **`LanguageCubit extends Cubit<AppLanguage>`**, 앱 루트 제공 | `MaterialApp.locale` 이 소비자. `ThemeCubit` 과 완전히 대칭 |
| 시스템 모드 표현 | `MaterialApp.locale = null` | null 이면 Flutter 가 기기 locale 협상을 한다. 시스템 → 명시 언어 → 시스템 왕복이 값 하나로 끝난다 |
| Failure 번역 | **`FailureCode` enum 을 Failure 에 더한다.** `message` 는 fallback 으로 유지 | domain 은 locale 을 모른다. 코드는 domain 에 안전하고, presentation 확장 `failure.localizedMessage(context)` 가 코드 → l10n 매핑을 한다. 코드가 없으면(미매핑 서버 원문) `message` 원문 표시 |
| Validators | **`ValidationError` enum 반환으로 변경** | 지금은 한국어 문자열을 직접 돌려줘 폼이 그대로 띄운다. enum 반환 + presentation 확장이면 core 가 locale 을 모른 채 번역된다 |
| DB 트리거 문구 | **DB 는 그대로 둔다.** mapper 의 매칭 목록이 코드로 변환 | 트리거 문구는 DB 계약이다([safety 계획](../safety/plan-block.md)). 문구 → `FailureCode` 매핑만 더하면 마이그레이션 없이 번역된다 |
| 날짜 표기 | `intl` 의 `DateFormat` 을 locale 로 | 지금 손 포맷은 한국어 고정이다. 목록의 날짜가 언어를 따라간다 |
| 번역 작성 | 구현 에이전트가 en·ja 초안 작성 | 토이 프로젝트. 어투: 앱 전반의 기존 한국어가 해요체가 아니라 간결한 평서형이므로, en 은 sentence case 간결형, ja 는 です·ます체 |

## 구조 (개명 후)

```
features/preferences/
├── domain/
│   ├── entity/app_theme_mode.dart        (이동)
│   ├── entity/app_language.dart          enum 4개 + code + fromCode
│   ├── repository/theme_repository.dart  (이동)
│   ├── repository/language_repository.dart
│   └── usecase/preferences_use_case.dart ← facade 통합 (구 ThemeUseCase)
├── data/                                 theme 계열 이동 + language 계열 신설
└── presentation/
    └── cubit/{theme_cubit,language_cubit}.dart
```

l10n 산출물은 `app/lib/l10n/` (`app_ko.arb` · `app_en.arb` · `app_ja.arb`,
생성 클래스 `AppLocalizations`). `l10n.yaml` 로 설정한다.

`FailureCode` enum 은 `core/error/failure_code.dart`. 코드 → 문구 확장은
`core/l10n/failure_localizations.dart` (presentation 전용 — material import 허용).

## 언어 라벨은 번역하지 않는다

선택 다이얼로그의 언어 이름은 **각 언어의 자기 표기**로 고정한다 — '한국어' ·
'English' · '日本語'. 일본어 사용자가 언어를 잘못 바꿔 영어 화면에 갇혀도 자기
언어를 찾을 수 있어야 한다. '시스템 설정' 라벨만 현재 언어를 따른다.

## 테스트 이행 — 이 작업의 최대 위험

기존 위젯 테스트 수백 건이 `find.text('신고')` 처럼 한국어를 단언한다. 문자열을
`AppLocalizations` 로 빼는 순간, **delegates 없는 테스트 하니스는 빌드가 깨지고**,
delegates 를 넣더라도 기본 locale 이 en 이면 단언이 전부 어긋난다.

- 모든 위젯 테스트 하니스에 delegates + `locale: Locale('ko')` 를 고정한다.
  공용 pump 헬퍼가 있으면 그곳 한 번, 없으면 파일별로
- 한국어 단언은 **그대로 유지한다** — ko 가 template 언어라 원문이 곧 기대값이다.
  키 기반 단언으로 갈아타는 것은 이번 범위가 아니다
- en·ja 는 대표 화면 스모크 테스트(설정 화면이 en 으로 뜬다 등)로만 덮는다.
  세 언어 × 전 화면 매트릭스는 만들지 않는다
- **Patrol E2E 하니스도 같이 고정한다** (2026-08-27 추가). 위젯 테스트만 생각하고
  넘어갔다가 실제 실행에서 깨졌다 — 기본값이 '시스템'이고 에뮬레이터는 `en-US` 라
  앱이 영어로 뜨고 `$('회원가입').tap()` 이 실패했다. 기기 locale 을 바꾸는 대신
  `launchApp()` 이 `SharedPreferences` 의 `language` 를 `ko` 로 심는다. 어느
  에뮬레이터에서도 같게 돌아야 하기 때문이다 ([검수](../../testing/audit-2026-08-27.md))

## 완료 조건

- [x] 설정 → 언어에서 시스템 · 한국어 · English · 日本語를 고를 수 있다
- [x] 선택이 즉시 전체 화면에 적용되고 재시작 후 유지된다
- [x] 저장값이 없으면 기기 언어를 따른다 (ja 기기 → 일본어, 미지원 → 영어)
- [x] 사용자에게 직접 보이는 화면 문자열에 한국어 하드코딩이 남아 있지 않다
      (ARB · DB 매칭 키 · `Failure.message` 진단 fallback · 언어 자기표기는 유지)
- [x] 폼 검증 오류가 선택 언어로 뜬다
- [x] DB 트리거 거부(중복 신고 · 차단된 게시물 댓글 등)가 선택 언어로 뜬다
- [x] 매핑되지 않은 서버 오류는 원문 fallback 으로 뜬다 (죽지 않는다)
- [x] 날짜 표기가 언어를 따른다
- [x] `features/theme` 참조가 코드에 남아 있지 않다 (개명 완료 — 문서는 2026-08-27 에 따라잡았다)
- [x] 테마 기능이 개명 후에도 그대로 동작한다 (기존 테스트 통과)
