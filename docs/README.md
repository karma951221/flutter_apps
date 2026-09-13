# daylog 문서 허브

문서는 목적별로 한 곳에서만 관리한다. 같은 내용을 여러 문서에 복사하지 않고, 이
허브와 상대 링크로 연결한다.

| 문서 | 단일 진실 소스 |
|---|---|
| [기획](overview.md) | 제품 목표, 범위, 결정과 근거 |
| [진행 현황](status.md) | 단계별 체크리스트, 다음 할 일 |
| [스키마](schema.md) | 테이블·RLS·GRANT의 현재 모습 |
| [아키텍처](architecture.md) | 앱 구조, 계층·의존성·구현 규칙 |
| [의존 그래프](dependencies.md) | 패키지·feature 간 실제 의존 관계와 그 성격 |
| [개발환경](setup.md) | 로컬 Supabase, 앱 실행, 재현 절차 |
| [테스트](testing/README.md) | 실행 방법, 테스트 구조, feature별 범위, 컨벤션 검사 |
| [E2E](testing/e2e.md) | Patrol 설정, 에뮬레이터 실행, 셀렉터 규칙 |
| [기능 문서](features/) | feature별 `plan.md`(화면·상태·완료 조건)와 `history.md`(구현 기록) |
| [둘째 앱 commute](features/commute/plan.md) | 통근 시간 앱 — 패키지 경계 시험. [기록](features/commute/history.md) · [테스트](testing/features/commute.md) · [설계](superpowers/specs/2026-09-13-commute-app-design.md) |

## 빠른 시작

1. 지금 어디까지 왔는지는 [진행 현황](status.md)을 본다.
2. 환경을 준비할 때는 [개발환경](setup.md)을 따른다.
3. 구조나 구현 규칙을 확인할 때는 [아키텍처](architecture.md)를 본다.
4. 테이블·정책·권한을 확인하거나 바꿀 때는 [스키마](schema.md)를 본다.
5. 테스트를 추가하거나 실행할 때는 [테스트 가이드](testing/README.md)를 본다.

## 문서 유지 규칙

- 구현 규칙·명령·테스트 범위는 해당 단일 문서만 수정하고, 다른 문서에서는 링크한다.
- 스키마를 바꾸면 마이그레이션과 [스키마 문서](schema.md)를 같은 커밋에서 함께 갱신한다.
- 확정되지 않은 계획은 [기획](overview.md)에만 두고, 진행 상태는 [진행 현황](status.md)에만 적는다.
- feature 착수 전에 `features/<feature>/plan.md`(화면·상태·완료 조건)를 쓰고,
  구현 과정과 일회성 문제 해결은 같은 폴더의 `history.md`에 기록한다.
- 링크는 Obsidian과 일반 Markdown 뷰어 모두에서 동작하는 상대 Markdown 링크를 쓴다.
  깨진 링크는 `apps/trader/test/convention/documentation_links_test.dart`가 잡는다.
