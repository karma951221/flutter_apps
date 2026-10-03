# socialapp 문서 허브

모노레포다. 앱마다 자기 문서를 `apps/<app>/docs/` 에 두고, 이 폴더에는 앱들이 함께
쓰는 문서만 둔다. 같은 내용을 여러 문서에 복사하지 않고 상대 링크로 연결한다.

## 앱

| 앱 | 한 줄 | 허브 |
|---|---|---|
| trader (daylog) | 과거 시세로 모의투자하고 결과를 소셜 피드에 공유한다. Supabase 백엔드 | [트레이더 허브](../apps/trader/docs/README.md) |
| commute (통근) | 집·회사 역으로 출퇴근 소요 시간을 본다. 백엔드 없음 | [통근 허브](../apps/commute/docs/README.md) |
| pawlog (강아지 산책) | 강아지 산책을 GPS 로 기록하고 피드로 돌아본다. v1 로컬 전용(drift), v2 Supabase 소셜. 기획 단계 | [pawlog 허브](../apps/pawlog/docs/README.md) |

## 공통 문서

| 문서 | 단일 진실 소스 |
|---|---|
| [전체 진행 현황](status.md) | 모노레포 작업 · 앱별 한 줄 상태 |
| [아키텍처](architecture.md) | 패키지 구조, 계층·의존성·구현 규칙 |
| [의존 그래프](dependencies.md) | 패키지·feature 간 실제 의존 관계와 그 성격 |
| [개발환경](setup.md) | 도구 버전, 앱 실행, iOS, 공통 함정 |
| [테스트](testing/README.md) | 실행 방법, 테스트 구조, 컨벤션 검사 |
| [스펙 · 실행 계획](superpowers/) | 브레인스토밍 스펙(`specs/`)과 실행 계획(`plans/`) 기록 |

## 앱 문서의 모양

```
apps/<app>/docs/
  README.md      앱 허브
  status.md      그 앱 진행 현황의 단일 기준
  ...            기획 · 스키마 · 계획 · 기록 · 테스트
```

트레이더는 feature 가 많아 `features/<name>/` 아래에 `plan.md` · `history.md` ·
`testing.md` 를 한 벌씩 둔다. 통근은 feature 가 하나라 `docs/` 바로 아래에 둔다.
pawlog 는 기획서(`overview.md`)를 먼저 두고 feature 문서는 트레이더처럼 `features/<name>/` 에 둔다.

## 문서 유지 규칙

- 진행 상태는 해당 앱의 `status.md` 에만 적는다. 모노레포 공통 작업은 [전체 진행 현황](status.md)에 적는다.
- feature 착수 전에 `plan.md`(화면·상태·완료 조건)를 쓰고, 완료하면 같은 폴더에
  `history.md`(구현 기록)와 `testing.md`(테스트 범위)를 남긴다.
- 스키마를 바꾸면 마이그레이션과 [트레이더 스키마 문서](../apps/trader/docs/schema.md)를 같은 커밋에서 함께 갱신한다.
- 구현 규칙·명령·테스트 범위는 해당 단일 문서만 수정하고, 다른 문서에서는 링크한다.
- 링크는 Obsidian과 일반 Markdown 뷰어 모두에서 동작하는 상대 Markdown 링크를 쓴다.
  깨진 링크는 `apps/trader/test/convention/documentation_links_test.dart`가
  `docs/` · `apps/*/docs/` · `CLAUDE.md` 전체에서 잡는다.
