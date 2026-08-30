# F7 safety — 신고 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 부적절한 게시물 · 댓글 · 사용자를 신고한다. 신고는 접수만 되고 처리는 Studio 직접 조회로 한다. 차단은 이번 범위가 아니다.

**Architecture:** `reports` 한 테이블에 폴리모픽(`target_type` + `target_id`)으로 담는다. FK 가 없으므로 대상 존재·자기 신고 검사를 BEFORE INSERT 트리거가 맡는다. 앱은 `features/safety` 하나를 새로 만들고 `ReportTarget` sealed union 으로 세 대상을 일반화한다. **쓰기 전용 feature** 라 목록 조회·DTO·커서가 없다. 화면은 새 라우트 없이 기존 세 곳(`PostTile` · `CommentTile` · `ProfilePage`)에 메뉴를 붙이고 바텀시트 하나를 띄운다.

**Tech Stack:** Flutter · bloc/cubit · freezed 3 · get_it + injectable · supabase_flutter · PostgreSQL(로컬 Supabase) · mocktail · bloc_test

**스펙 (요구사항의 단일 기준):** [docs/features/safety/plan.md](../../features/safety/plan.md)

## Global Constraints

모든 태스크의 요구사항에 아래가 암묵적으로 포함된다.

- **Supabase 타입은 `data/` 밖으로 나가지 않는다.** `PostgrestException` · `Session` · `User` 가 `domain/` 이나 `presentation/` 에 등장하면 안 된다 ([아키텍처 규칙 ①](../../architecture.md))
- **Repository 는 `domain/repository/` 의 `abstract interface class` 로 선언하고 `data/repository/` 구현체를 `@LazySingleton(as: …)` 로 등록한다** (규칙 ②)
- **presentation 은 feature 별 UseCase facade 하나만 주입받는다.** scenario 는 `@injectable` 을 붙이지 않는 일반 Dart 클래스다 (규칙 ③)
- **Supabase 예외는 `data/repository/` 의 error handler mixin 이 `Result`/`Failure` 로 변환한다.** domain 은 예외를 보지 않는다 (규칙 ④)
- **feature 간 참조는 `domain` 계층만** (규칙 ⑥)
- **Freezed 는 두 패턴만 쓴다** ([CLAUDE.md](../../../CLAUDE.md)): 단일 불변 모델은 Primary Constructor, 여러 변형은 `sealed class` + named `factory`. 분기는 `when`/`map` 대신 Dart pattern matching `switch`
- **생성 파일(`.freezed.dart` · `.g.dart` · `injection.config.dart`)은 직접 수정하지 않는다.** `dart run build_runner build --delete-conflicting-outputs` 로만 갱신한다
- **UI 는 `design_system/widget/` 의 공통 위젯을 먼저 쓴다.** 색·여백·타이포는 `design_system/theme/` 토큰만 쓰고 하드코딩하지 않는다 ([CLAUDE.md](../../../CLAUDE.md))
- **테스트 위치는 구현 구조를 그대로 미러링한다.** `app/lib/features/safety/` ↔ `app/test/features/safety/`
- **스키마를 바꾸면 같은 커밋에서 [docs/schema.md](../../schema.md) 를 갱신한다.** Studio UI 로 테이블을 만들지 않는다
- **문서 링크는 상대 Markdown 링크만 쓴다.** `app/test/convention/documentation_links_test.dart` 가 깨진 링크를 잡는다
- **커밋 메시지는 한국어 현재형이다** — `feat(safety): 신고를 접수한다`
- **DB 값과 앱 상수는 일치해야 한다.** 상세 설명 최대 길이는 DB CHECK 와 `ReportPolicy.maxDetailLength` 양쪽에서 **500**
- **사유 코드는 5개다** — `'spam'` · `'abuse'` · `'sexual'` · `'violence'` · `'other'`. DB CHECK 와 `ReportReason.code` 가 같은 문자열을 쓴다
- **대상 코드는 3개다** — `'post'` · `'comment'` · `'user'`. DB CHECK 와 `report_target_mapper` 가 같은 문자열을 쓴다

**작업 디렉터리:** SQL 은 리포지터리 루트 기준, Dart 명령은 `app/` 기준이다.

**검증 명령:**

```bash
supabase db reset          # 리포지터리 루트. 마이그레이션 전체 재적용
cd app && flutter analyze
cd app && flutter test
```

---

### Task 1: 신고 스키마 — 테이블 · 트리거 · RLS · GRANT

**Files:**
- Create: `supabase/migrations/20260824140000_add_reports.sql`
- Modify: `docs/schema.md` (§1 관계도, §3 공통 함수 아래에 새 절 추가)

**Interfaces:**
- Consumes: 기존 `public.posts` · `public.post_comments` · `public.profiles`
- Produces: 테이블 `public.reports`, 트리거 함수 `public.enforce_report_target()`

- [ ] **Step 1: 마이그레이션 파일 작성**

`supabase/migrations/20260824140000_add_reports.sql` 에 아래를 그대로 쓴다.

```sql
-- F7 신고. 폴리모픽 대상(게시물·댓글·사용자) 한 테이블.
-- 설계 근거는 docs/features/safety/plan.md 에 있다.

create table public.reports (
  id          uuid        primary key default gen_random_uuid(),
  reporter_id uuid        not null default auth.uid()
                          references public.profiles (id) on delete cascade,
  target_type text        not null,
  target_id   uuid        not null,
  reason      text        not null,
  detail      text,
  status      text        not null default 'pending',
  created_at  timestamptz not null default now(),

  constraint reports_target_type_valid check (
    target_type in ('post', 'comment', 'user')
  ),
  constraint reports_reason_valid check (
    reason in ('spam', 'abuse', 'sexual', 'violence', 'other')
  ),
  constraint reports_status_valid check (
    status in ('pending', 'resolved', 'rejected')
  ),
  -- 빈 문자열이 저장되는 상태를 없앤다. null 이거나, 공백을 걷어내고 1자 이상이다.
  constraint reports_detail_length check (
    detail is null or char_length(btrim(detail)) between 1 and 500
  ),
  -- 컬럼 둘만 보면 판정되는 유일한 자기 신고. 나머지는 트리거가 본다.
  constraint reports_not_self_user check (
    not (target_type = 'user' and reporter_id = target_id)
  ),
  -- 1인 1회. 대상별 신고자 수가 곧 신고 건수가 된다.
  constraint reports_once unique (reporter_id, target_type, target_id)
);

-- 둘 다 운영(Studio) 조회용이다. 앱에는 신고 목록 화면이 없다.
create index reports_target_idx on public.reports (target_type, target_id);
create index reports_status_created_at_idx
  on public.reports (status, created_at desc);

-- 폴리모픽이라 FK 가 없다. FK 가 해주던 일(존재하는 대상인가)과 정책이 못 하는
-- 일(내 것이 아닌가)을 트리거가 함께 본다.
--
-- security definer 가 필요하다: post_comments 는 content 컬럼에 SELECT 를 주지
-- 않으므로(docs/features/comment/plan.md) invoker 로 두면 대상 행을 읽지 못한다.
-- search_path = '' 는 definer 함수의 필수 안전장치라 모든 객체를 스키마까지 적는다.
create function public.enforce_report_target()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_author uuid;
begin
  if new.target_type = 'post' then
    select author_id into target_author
      from public.posts
     where id = new.target_id and deleted_at is null;
    if not found then
      raise exception '신고할 대상이 없습니다';
    end if;
    if target_author = new.reporter_id then
      raise exception '내 게시물은 신고할 수 없습니다';
    end if;

  elsif new.target_type = 'comment' then
    select author_id into target_author
      from public.post_comments
     where id = new.target_id and deleted_at is null;
    if not found then
      raise exception '신고할 대상이 없습니다';
    end if;
    if target_author = new.reporter_id then
      raise exception '내 댓글은 신고할 수 없습니다';
    end if;

  elsif new.target_type = 'user' then
    perform 1 from public.profiles where id = new.target_id;
    if not found then
      raise exception '신고할 대상이 없습니다';
    end if;
  end if;

  return new;
end;
$$;

create trigger reports_enforce_target
  before insert on public.reports
  for each row execute function public.enforce_report_target();

alter table public.reports enable row level security;

-- 조회: 본인 신고만. 남이 무엇을 신고했는지는 누구도 볼 수 없다.
create policy "reports_select_own"
  on public.reports for select to authenticated
  using ((select auth.uid()) = reporter_id);

-- 삽입: 본인 것만.
create policy "reports_insert_own"
  on public.reports for insert to authenticated
  with check ((select auth.uid()) = reporter_id);

-- UPDATE · DELETE 정책은 두지 않는다. 신고는 취소되지 않고,
-- status 변경은 service_role 의 일이다.

-- reporter_id 와 status 에 INSERT 를 주지 않는 것이 위조를 막는 방법이다.
-- reporter_id 는 default auth.uid() 가 채우고 status 는 항상 pending 으로 시작한다.
grant select on public.reports to authenticated;
grant insert (target_type, target_id, reason, detail)
  on public.reports to authenticated;
```

- [ ] **Step 2: 적용과 검증**

리포지터리 루트에서 `supabase db reset` 을 실행해 전체 마이그레이션이 통과하는지 확인한다.

그다음 `psql` 로 아래를 확인하고 결과를 report 에 적는다. 접속은
`psql postgresql://postgres:postgres@127.0.0.1:54322/postgres` 다.

| 확인할 것 | 방법 | 기대 |
|---|---|---|
| 제약 6개가 붙었는가 | `\d public.reports` | `reports_target_type_valid` · `reports_reason_valid` · `reports_status_valid` · `reports_detail_length` · `reports_not_self_user` · `reports_once` |
| 인덱스 3개 | `\d public.reports` | PK · `reports_target_idx` · `reports_status_created_at_idx` · unique 제약의 인덱스 |
| GRANT 가 컬럼 단위인가 | `\dp public.reports` | insert 가 `target_type,target_id,reason,detail` 에만 |
| 빈 상세 설명 거부 | `insert ... detail = ''` 를 service_role 로 시도 | `23514` 로 거부 |
| 공백만 있는 상세 설명 거부 | `detail = '   '` | `23514` 로 거부 |
| 자기 사용자 신고 거부 | `target_type='user'` 에 `reporter_id = target_id` | `23514` 로 거부 |

- [ ] **Step 3: `docs/schema.md` 갱신**

같은 커밋에서 갱신한다. 세 곳을 손댄다.

1. **§1 관계** — 관계도 아래 문단의 "앞으로 추가될 테이블(`follows` · `blocks` · `reports`)" 에서 `reports` 를 빼고, `blocks` · `follows` 만 남긴다. 관계도에는 `reports` 를 **넣지 않는다** — FK 가 없어 선으로 이을 수 없다. 대신 문단으로 "`reports` 는 폴리모픽이라 관계도에 선이 없다. `reporter_id` 만 `profiles` 를 참조한다" 를 적는다.
2. **새 절** — 기존 절 번호 뒤에 `reports` 절을 추가한다. 위 SQL 그대로의 DDL, 제약 6개의 의미, 트리거가 하는 검사 3종 표, RLS 2개, GRANT 를 적는다. 트리거가 `security definer` 여야 하는 이유(§9 `post_comments` 의 컬럼 GRANT)를 함께 적는다.
3. **§2 공통 규칙** — 규칙을 새로 만들지 않는다. `reports` 는 "GRANT 는 컬럼 단위로 최소한만 준다" 와 "소유자 컬럼은 DB 가 채운다" 를 그대로 따르는 사례다.

- [ ] **Step 4: 커밋**

```
feat(db): 신고 테이블과 대상 검증 트리거를 만든다
```

**Verification:**
- [ ] `supabase db reset` 이 오류 없이 끝난다
- [ ] Step 2 의 표에 있는 여섯 가지를 모두 확인했고 결과를 report 에 적었다
- [ ] `docs/schema.md` 가 세 곳 모두 갱신됐다
- [ ] `cd app && flutter test test/convention` 이 통과한다 (문서 링크 검사)

---

### Task 2: `features/safety` — domain · data · DI

**Files:**
- Create: `app/lib/features/safety/domain/entity/report_target.dart`
- Create: `app/lib/features/safety/domain/entity/report_reason.dart`
- Create: `app/lib/features/safety/domain/report_policy.dart`
- Create: `app/lib/features/safety/domain/repository/report_repository.dart`
- Create: `app/lib/features/safety/domain/usecase/report_use_case.dart`
- Create: `app/lib/features/safety/domain/usecase/scenario/submit_report_scenario.dart`
- Create: `app/lib/features/safety/data/datasource/report_data_source.dart`
- Create: `app/lib/features/safety/data/datasource/supabase_report_data_source.dart`
- Create: `app/lib/features/safety/data/mapper/report_target_mapper.dart`
- Create: `app/lib/features/safety/data/repository/report_repository_impl.dart`
- Create: `app/lib/features/safety/data/repository/report_repository_error_handler.dart`
- Create: `app/test/features/safety/domain/report_policy_test.dart`
- Create: `app/test/features/safety/domain/usecase/scenario/submit_report_scenario_test.dart`
- Create: `app/test/features/safety/data/mapper/report_target_mapper_test.dart`
- Create: `app/test/features/safety/data/repository/report_repository_impl_test.dart`
- Modify: `app/lib/core/data/mapper/supabase_error_mapper.dart`
- Modify: `app/test/core/data/mapper/supabase_error_mapper_test.dart` (없으면 Create)

**Interfaces:**
- Consumes: `core/result/result.dart` · `core/error/failure.dart` · Task 1 의 `public.reports`
- Produces: `ReportTarget` · `ReportReason` · `ReportPolicy` · `ReportUseCase.submit(...)`

`features/reaction` 이 이 태스크의 기준 예시다. 같은 파일 배치, 같은 DI 어노테이션,
같은 error handler mixin 모양을 쓴다. 다른 점은 **조회가 없다**는 것뿐이다.

- [ ] **Step 1: domain 엔티티**

`report_target.dart` — `ReactionTarget` 과 같은 축이다. 변형이 셋인 것만 다르다.

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'report_target.freezed.dart';

/// 신고할 대상.
///
/// DB 가 폴리모픽(`target_type` + `target_id`)이라 FK 가 없다. 대상이 실재하는지는
/// 트리거가 보고, 앱에서는 이 타입이 "무엇을 신고하는가" 의 단일 표현이다.
/// 대상이 늘면 여기 변형 하나와 data 의 매핑 한 줄만 는다.
@freezed
sealed class ReportTarget with _$ReportTarget {
  const factory ReportTarget.post(String id) = ReportPostTarget;
  const factory ReportTarget.comment(String id) = ReportCommentTarget;
  const factory ReportTarget.user(String id) = ReportUserTarget;
}
```

`report_reason.dart` — `ReactionType` 과 같은 모양이다. `code` 는 DB CHECK 와,
`label` 은 시트에 그대로 나온다.

```dart
/// 신고 사유. [code] 는 DB 의 reports_reason_valid CHECK 와 같은 문자열이어야 한다.
///
/// 자유 서술이 아니라 고정 목록인 이유는 운영(Studio 직접 조회)이 집계할 수 있어야
/// 하기 때문이다. 맥락은 detail 이 받는다.
enum ReportReason {
  spam('spam', '스팸 또는 광고'),
  abuse('abuse', '욕설 또는 혐오 표현'),
  sexual('sexual', '음란물 또는 선정적인 내용'),
  violence('violence', '폭력 또는 위협'),
  other('other', '기타');

  const ReportReason(this.code, this.label);

  final String code;
  final String label;
}
```

`report_policy.dart` — `CommentPolicy` 와 같은 자리의 상수 + 정규화.

```dart
/// 신고 domain 정책.
///
/// DB 의 reports_detail_length CHECK 와 같은 값을 쓴다. 앱 검증은 UX 이고 최종
/// 판정은 DB 가 하지만, 두 값이 어긋나면 사용자에게 날것의 DB 오류가 간다.
abstract final class ReportPolicy {
  /// 상세 설명 최대 길이. docs/schema.md 의 reports_detail_length 와 같아야 한다.
  static const maxDetailLength = 500;

  /// 빈 입력을 null 로 만든다.
  ///
  /// DB 는 빈 문자열을 거부한다 — 저장 가능한 상태를 "null 이거나 내용이 있음"
  /// 하나로 줄이기 위해서다. 앱이 짝을 맞춰 정규화하므로 정상 경로에서 그
  /// 제약에 걸릴 일은 없다.
  static String? normalizeDetail(String? raw) {
    final trimmed = raw?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
```

- [ ] **Step 2: repository 인터페이스와 usecase**

`domain/repository/report_repository.dart`:

```dart
import '../../../../core/result/result.dart';
import '../entity/report_reason.dart';
import '../entity/report_target.dart';

/// 신고 저장소.
///
/// 조회는 여기 없다. RLS 가 본인 신고 조회를 열어 두지만 화면이 쓰지 않는다 —
/// 쓰지 않는 경로를 만들면 유지할 것만 는다.
abstract interface class ReportRepository {
  /// 신고를 접수한다. 중복·자기 신고·삭제된 대상은 서버가 거부한다.
  Future<Result<void>> submitReport(
    ReportTarget target, {
    required ReportReason reason,
    String? detail,
  });
}
```

`domain/usecase/scenario/submit_report_scenario.dart`:

```dart
import '../../../../../core/result/result.dart';
import '../../entity/report_reason.dart';
import '../../entity/report_target.dart';
import '../../report_policy.dart';
import '../../repository/report_repository.dart';

/// 신고 접수.
///
/// 상세 설명 정규화가 여기 있는 이유: 빈 값을 null 로 바꾸는 것은 화면의 사정이
/// 아니라 저장 규칙이다. 어느 화면에서 신고하든 같은 값이 저장돼야 한다.
class SubmitReportScenario {
  const SubmitReportScenario(this._repository);

  final ReportRepository _repository;

  Future<Result<void>> call(
    ReportTarget target, {
    required ReportReason reason,
    String? detail,
  }) => _repository.submitReport(
    target,
    reason: reason,
    detail: ReportPolicy.normalizeDetail(detail),
  );
}
```

`domain/usecase/report_use_case.dart` — `ReactionUseCase` 와 같은 모양이다.
시나리오가 하나뿐이어도 facade 를 두는 것은 규칙 ③ 을 지키고, 차단이 붙을 자리를
만들어 두기 위해서다.

```dart
import 'package:injectable/injectable.dart';

import '../../../../core/result/result.dart';
import '../entity/report_reason.dart';
import '../entity/report_target.dart';
import '../repository/report_repository.dart';
import 'scenario/submit_report_scenario.dart';

/// 신고 feature 의 presentation 진입점.
abstract interface class ReportUseCase {
  Future<Result<void>> submit(
    ReportTarget target, {
    required ReportReason reason,
    String? detail,
  });
}

@LazySingleton(as: ReportUseCase)
class DefaultReportUseCase implements ReportUseCase {
  DefaultReportUseCase(this._repository);

  final ReportRepository _repository;

  @override
  Future<Result<void>> submit(
    ReportTarget target, {
    required ReportReason reason,
    String? detail,
  }) => SubmitReportScenario(
    _repository,
  )(target, reason: reason, detail: detail);
}
```

- [ ] **Step 3: data 계층**

`data/mapper/report_target_mapper.dart` — `'post'` · `'comment'` · `'user'` 문자열을
아는 **유일한 곳**이다. `SupabaseReactionDataSource._mapping` 과 같은 역할이지만,
반응과 달리 테이블이 하나라 컬럼이 아니라 `target_type` 값을 고른다.

```dart
import '../../domain/entity/report_target.dart';

/// 대상 → DB 의 (target_type, target_id) 매핑이 있는 유일한 곳.
///
/// 대상이 늘면 여기 한 줄과 ReportTarget 의 변형, 그리고 CHECK 제약만 는다.
/// domain 과 presentation 은 그대로다.
abstract final class ReportTargetMapper {
  static ({String type, String id}) toPayload(ReportTarget target) =>
      switch (target) {
        ReportPostTarget(:final id) => (type: 'post', id: id),
        ReportCommentTarget(:final id) => (type: 'comment', id: id),
        ReportUserTarget(:final id) => (type: 'user', id: id),
      };
}
```

`data/datasource/report_data_source.dart`:

```dart
import '../../domain/entity/report_reason.dart';
import '../../domain/entity/report_target.dart';

abstract interface class ReportDataSource {
  Future<void> submitReport(
    ReportTarget target, {
    required ReportReason reason,
    String? detail,
  });
}
```

`data/datasource/supabase_report_data_source.dart`:

```dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entity/report_reason.dart';
import '../../domain/entity/report_target.dart';
import '../mapper/report_target_mapper.dart';
import 'report_data_source.dart';

@LazySingleton(as: ReportDataSource)
class SupabaseReportDataSource implements ReportDataSource {
  SupabaseReportDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<void> submitReport(
    ReportTarget target, {
    required ReportReason reason,
    String? detail,
  }) async {
    if (_client.auth.currentUser == null) {
      throw const Failure.auth(message: '로그인이 필요합니다');
    }

    final payload = ReportTargetMapper.toPayload(target);

    // reporter_id 와 status 는 보내지 않는다. GRANT 에 없어서 보내면 42501 로
    // 막히고, DB 의 default 가 채우므로 위조 경로가 없다.
    await _client.from('reports').insert({
      'target_type': payload.type,
      'target_id': payload.id,
      'reason': reason.code,
      'detail': detail,
    });
  }
}
```

`data/repository/report_repository_error_handler.dart` 는
`CommentRepositoryErrorHandler` 와 이름만 다르고 내용은 같다.

`data/repository/report_repository_impl.dart` 는 `ReactionRepositoryImpl` 과 같은
모양으로 `guard(() => _dataSource.submitReport(...))` 하나다.

- [ ] **Step 4: `SupabaseErrorMapper` 에 신고 문구 등록**

`app/lib/core/data/mapper/supabase_error_mapper.dart` 의 `_constraintFrom` 에
아래를 더한다. 등록하지 않으면 `23505` · `23514` 의 기본 문구로 덮여 원인이 사라진다.

제약 이름 분기 두 개를 `post_reactions_type_valid` 분기 **아래**에 넣는다.

```dart
    if (raw.contains('reports_once')) {
      return const Failure.validation(message: '이미 신고한 항목입니다');
    }
    if (raw.contains('reports_detail_length')) {
      return const Failure.validation(
        message: '상세 설명은 500자 이하여야 합니다',
        field: 'detail',
      );
    }
    if (raw.contains('reports_not_self_user')) {
      return const Failure.validation(message: '자기 자신은 신고할 수 없습니다');
    }
```

그리고 `_commentDepthMessages` 바로 아래에 트리거 문구 목록을 더하고, 기존
`for (final message in _commentDepthMessages)` 루프와 같은 방식으로 검사한다.

```dart
  /// `enforce_report_target()` 이 던지는 문구들. 트리거의 raise 문과 같아야 한다.
  static const _reportTargetMessages = [
    '신고할 대상이 없습니다',
    '내 게시물은 신고할 수 없습니다',
    '내 댓글은 신고할 수 없습니다',
  ];
```

두 목록을 한 번에 도는 형태로 합쳐도 좋다 — 다만 **주석이 어느 트리거의 문구인지
가리키는 성질은 유지한다.**

- [ ] **Step 5: DI 코드 생성**

```bash
cd app && dart run build_runner build --delete-conflicting-outputs
```

`injection.config.dart` 에 `ReportDataSource` · `ReportRepository` · `ReportUseCase`
셋이 등록됐는지 확인한다. 직접 편집하지 않는다.

- [ ] **Step 6: 테스트**

기존 테스트의 모양을 따른다 — `test/features/reaction/` 과
`test/features/comment/data/repository/comment_repository_impl_test.dart` 가 기준이다.
mocktail 로 `ReportDataSource` 를 가짜로 만든다.

| 파일 | 검증 |
|---|---|
| `domain/report_policy_test.dart` | `normalizeDetail` — `null` → `null`, `''` → `null`, `'   '` → `null`, `' 내용 '` → `'내용'`, 500자 문자열은 그대로 |
| `domain/usecase/scenario/submit_report_scenario_test.dart` | 시나리오가 **정규화된 detail 로** repository 를 부른다 (공백만 넘기면 `null` 이 전달된다). repository 의 `Err` 를 그대로 돌려준다 |
| `data/mapper/report_target_mapper_test.dart` | 세 변형이 각각 `'post'` · `'comment'` · `'user'` 와 원래 id 로 간다 |
| `data/repository/report_repository_impl_test.dart` | 성공 시 `Ok`. `PostgrestException(code: '23505', message: '... reports_once ...')` 가 `ValidationFailure('이미 신고한 항목입니다')` 로 변환된다. 트리거 문구 `'내 게시물은 신고할 수 없습니다'` 가 같은 문구의 `ValidationFailure` 로 변환된다 |
| `core/data/mapper/supabase_error_mapper_test.dart` | 위 제약 3개와 트리거 문구 3개가 각각 의도한 `Failure` 로 매핑된다. 기존 댓글·게시물 매핑이 깨지지 않는다 |

`supabase_error_mapper_test.dart` 가 이미 있으면 케이스를 **추가**하고, 없으면
새로 만들되 신고 관련 케이스만 다룬다 (기존 매핑 전체를 뒤늦게 테스트하는 것은 이
태스크의 범위가 아니다).

- [ ] **Step 7: 커밋**

```
feat(safety): 신고 domain 과 data 계층을 만든다
```

**Verification:**
- [ ] `cd app && flutter analyze` 에 새 경고가 없다
- [ ] `cd app && flutter test test/features/safety test/core` 가 통과한다
- [ ] `cd app && flutter test` 전체가 통과한다
- [ ] `injection.config.dart` 에 셋이 등록됐다
- [ ] `domain/` 과 `presentation/` 어디에도 `PostgrestException` 이 없다

---

### Task 3: `AppOverflowMenu` — 공통 더보기 메뉴

**Files:**
- Create: `app/lib/design_system/widget/app_overflow_menu.dart`
- Create: `app/test/design_system/widget/app_overflow_menu_test.dart`

**Interfaces:**
- Produces: `AppOverflowMenu<T>` — Task 5 의 세 진입점이 쓴다

이 태스크는 **화면 배선을 하지 않는다.** 위젯과 테스트만 만들고, 실제로 붙이는 것은
Task 5 다. 순서를 나눈 이유는 세 화면이 같은 위젯을 쓰는지 리뷰가 확인할 수 있게
하기 위해서다.

- [ ] **Step 1: 위젯**

`PopupMenuButton<T>` 을 얇게 감싼다. `design_system/widget/` 의 기존 위젯
(`AppCountAction` 이 가장 가깝다) 과 같은 결로 쓴다 — 토큰은
`design_system/theme/` 것만 쓰고 색·여백을 하드코딩하지 않는다.

요구사항:

- 생성자: `AppOverflowMenu({required List<AppOverflowMenuItem<T>> items, required ValueChanged<T> onSelected, String tooltip = '더보기', Key? key})`
- `AppOverflowMenuItem<T>` — `{required T value, required String label, IconData? icon, bool isDestructive = false}`
- `isDestructive` 인 항목은 라벨과 아이콘을 `colorScheme.error` 로 그린다 (삭제가 이걸 쓴다)
- `items` 가 비면 **아무것도 그리지 않는다** (`SizedBox.shrink()`). 호출부가 "항목이 없으면 메뉴를 숨긴다" 를 매번 조건문으로 쓰지 않게 하기 위해서다
- 아이콘은 `Icons.more_vert`, `visualDensity: VisualDensity.compact`

문서 주석에 **왜 공통으로 올렸는지**를 적는다 — 게시물 · 댓글 · 프로필 세 곳이 같은
모양을 쓰고, [CLAUDE.md](../../../CLAUDE.md) 규칙 4 의 "반복 사용" 조건에 해당한다.

- [ ] **Step 2: 위젯 테스트**

`test/design_system/` 아래에 기존 위젯 테스트가 있으면 그 모양을 따른다.

| 검증 | 방법 |
|---|---|
| 항목이 없으면 아무것도 안 그린다 | `items: []` 로 펌프 → `find.byIcon(Icons.more_vert)` 가 `findsNothing` |
| 탭하면 항목이 뜬다 | 아이콘 탭 → `pumpAndSettle` → 라벨 텍스트가 보인다 |
| 선택하면 값이 온다 | 항목 탭 → `onSelected` 가 그 `value` 로 한 번 불린다 |
| destructive 는 error 색이다 | 해당 라벨 `Text` 위젯의 `style.color` 가 `colorScheme.error` |

- [ ] **Step 3: 커밋**

```
feat(design-system): 공통 더보기 메뉴를 추가한다
```

**Verification:**
- [ ] `cd app && flutter analyze` 에 새 경고가 없다
- [ ] `cd app && flutter test test/design_system` 이 통과한다
- [ ] 색·여백이 `design_system/theme/` 토큰과 `Theme.of(context)` 에서만 온다

---

### Task 4: 신고 시트 — `ReportCubit` · `ReportState` · `ReportSheet`

**Files:**
- Create: `app/lib/features/safety/presentation/cubit/report_state.dart`
- Create: `app/lib/features/safety/presentation/cubit/report_cubit.dart`
- Create: `app/lib/features/safety/presentation/widget/report_sheet.dart`
- Create: `app/test/features/safety/presentation/cubit/report_cubit_test.dart`
- Create: `app/test/features/safety/presentation/widget/report_sheet_test.dart`

**Interfaces:**
- Consumes: Task 2 의 `ReportUseCase` · `ReportReason` · `ReportTarget` · `ReportPolicy`
- Produces: `ReportSheet.show(BuildContext context, ReportTarget target)` — Task 5 의 세 진입점이 부른다

- [ ] **Step 1: 상태**

`report_state.dart` — Primary Constructor 패턴이다 (`CommentState` 가 기준).
auth 의 `SubmitState` 는 그 feature 전용이므로 재사용하지 않는다.

```dart
@freezed
class ReportState with _$ReportState {
  const ReportState({
    this.reason,
    this.detail = '',
    this.isSubmitting = false,
    this.failure,
  });

  /// 선택된 사유. null 이면 아직 고르지 않았고 제출할 수 없다.
  @override
  final ReportReason? reason;

  /// 상세 설명 원문. 정규화는 저장 직전 domain 이 한다.
  @override
  final String detail;

  @override
  final bool isSubmitting;

  @override
  final Failure? failure;

  bool get canSubmit => reason != null && !isSubmitting;
}
```

- [ ] **Step 2: cubit**

`report_cubit.dart` — `@injectable` 로 등록하고 `ReportUseCase` 하나만 주입받는다
(규칙 ③). 기존 cubit 들과 같은 모양이다.

| 메서드 | 하는 일 |
|---|---|
| `selectReason(ReportReason reason)` | 사유를 바꾸고 `failure` 를 지운다 |
| `changeDetail(String value)` | 원문을 담는다. 검증하지 않는다 |
| `submit(ReportTarget target)` | `isSubmitting = true` → usecase 호출 → 결과에 따라 상태 갱신. 성공하면 `isSubmitting = false` 로 두고 `failure` 는 null |

`submit` 의 반환은 `Future<bool>` 로 두고 성공 여부를 돌려준다 — 시트를 닫는 것은
화면의 일이고, cubit 이 `BuildContext` 를 알면 안 된다.

성공/실패 분기는 `switch` 패턴 매칭을 쓴다 (`Ok` / `Err`).

- [ ] **Step 3: 시트**

`report_sheet.dart` — `showModalBottomSheet` 를 감싼 static 진입점 하나와
내부 `StatefulWidget`/`BlocBuilder` 구성이다.

```dart
static Future<void> show(BuildContext context, ReportTarget target)
```

`getIt<ReportCubit>()` 을 `BlocProvider` 로 감싸 시트 안에 준다. 기존 화면들이
`getIt` 을 쓰는 방식(`ProfilePage` 의 `BlocProvider(create: (_) => getIt<…>())`)과 같다.

구성:

| 구성 | 요구사항 |
|---|---|
| 제목 | `'신고'`, `textTheme.titleMedium` |
| 사유 목록 | `ReportReason.values` 를 `RadioListTile` 로. 라벨은 `reason.label` |
| 상세 설명 | **항상 보인다.** `TextField`, `maxLength: ReportPolicy.maxDetailLength`, `maxLines: 3`, 라벨 `'상세 설명 (선택)'`, 힌트 `'무엇이 문제인지 적어주세요'` |
| 제출 | `AppButton.primary`, 라벨 `'신고하기'`. `state.canSubmit` 이 false 면 비활성 |
| 제출 중 | 시트 전체를 `AbsorbPointer` 로 잠그고 버튼은 진행 표시 |
| 실패 | 시트를 **열어 둔 채** `state.failure?.message` 를 사유 목록 위에 `colorScheme.error` 로 보여준다 |
| 성공 | 시트를 닫고(`Navigator.pop`) 호출한 화면에서 `AppSnackBar.show` 로 `'신고가 접수되었습니다'` |

키보드가 올라올 때 가려지지 않도록 `isScrollControlled: true` 와
`padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom)` 를 쓴다.

성공 스낵바를 시트가 아니라 **호출한 화면**에서 띄우는 이유: 시트가 닫히면서
그 `BuildContext` 가 사라지므로 시트 안에서 띄우면 스낵바가 함께 사라진다.
`show` 가 `Future<bool>`(접수됐는지)을 돌려주고 호출부가 스낵바를 띄우게 한다 —
이 경우 시그니처는 `static Future<bool> show(...)` 다.

- [ ] **Step 4: 테스트**

`test/features/comment/presentation/cubit/comment_cubit_test.dart` 와
`post_comments_page_test.dart` 가 기준이다. `bloc_test` · mocktail 을 쓴다.

| 파일 | 검증 |
|---|---|
| `report_cubit_test.dart` | 사유 선택이 상태에 반영된다 · 사유 없이는 `canSubmit` 이 false · `submit` 이 `isSubmitting` 을 켰다 끈다 · 성공 시 `true` 를 돌려준다 · 실패 시 `failure` 가 담기고 `false` 를 돌려준다 · **정규화 전 원문이 usecase 로 간다** (정규화는 domain 책임) |
| `report_sheet_test.dart` | 사유 5개가 모두 보인다 · 사유 선택 전에는 제출 버튼이 비활성 · 상세 설명 입력칸이 **처음부터** 보인다 · 제출 성공 시 시트가 닫힌다 · 실패 시 시트가 열려 있고 오류 문구가 보인다 |

- [ ] **Step 5: 커밋**

```
feat(safety): 신고 시트를 만든다
```

**Verification:**
- [ ] `cd app && flutter analyze` 에 새 경고가 없다
- [ ] `cd app && flutter test test/features/safety` 가 통과한다
- [ ] 시트가 `AppButton.primary` 를 쓰고 색·여백을 하드코딩하지 않는다
- [ ] `ReportCubit` 에 `BuildContext` 가 없다

---

### Task 5: 진입점 배선 — 게시물 · 댓글 · 프로필

**Files:**
- Modify: `app/lib/features/post/presentation/widget/post_tile.dart`
- Modify: `app/lib/features/comment/presentation/widget/comment_tile.dart`
- Modify: `app/lib/features/comment/presentation/page/post_comments_page.dart`
- Modify: `app/lib/features/profile/presentation/page/profile_page.dart`
- Modify: `app/lib/features/feed/presentation/page/` 의 피드 화면 (PostTile 호출부)
- Modify: `app/test/features/profile/presentation/page/profile_page_test.dart`
- Create: `app/test/features/post/presentation/widget/post_tile_test.dart`
- Modify: `app/test/features/comment/presentation/page/post_comments_page_test.dart`

**Interfaces:**
- Consumes: Task 3 의 `AppOverflowMenu`, Task 4 의 `ReportSheet.show`
- Produces: 화면 세 곳의 신고 진입점

**주의:** `PostTile` 은 피드와 프로필이 함께 쓴다. 시그니처를 바꾸면 **두 호출부를 모두**
고쳐야 한다. 기존 `onEdit` · `onDelete` 의 nullable 규약을 깨지 않는다.

- [ ] **Step 1: `PostTile`**

`onReport` 콜백(`VoidCallback?`)을 더한다. `trailing` 의 조건부 `PopupMenuButton` 을
`AppOverflowMenu` 로 바꾸고, 항목을 상황에 따라 만든다.

- 내 글(`isMine`): 수정 · 삭제(destructive). 지금과 같다
- 남의 글: 신고
- 콜백이 null 인 항목은 목록에 넣지 않는다. 항목이 하나도 없으면 `AppOverflowMenu` 가 알아서 아무것도 그리지 않는다 (Task 3)

`_PostAction` enum 에 `report` 를 더한다.

문서 주석을 갱신한다 — "내 글일 때만 메뉴를 그린다" 는 설명이 더 이상 맞지 않는다.

- [ ] **Step 2: 피드 · 프로필의 `PostTile` 호출부**

두 곳 모두 `onReport` 를 넘긴다.

```dart
onReport: isMine
    ? null
    : () => _report(context, ReportTarget.post(post.id)),
```

`_report` 헬퍼는 `ReportSheet.show` 를 부르고, `true` 가 오면 `AppSnackBar.show` 로
`'신고가 접수되었습니다'` 를 띄운다. 두 화면이 같은 헬퍼를 각자 갖는다 — 화면 전용
private 함수라 공통화하지 않는다.

프로필의 `_ProfilePostList` 는 `isMine` 을 이미 갖고 있다. 타인 프로필에서만 신고가
붙는다.

- [ ] **Step 3: `CommentTile`**

삭제 `IconButton` 을 `AppOverflowMenu` 로 바꾸고 `onReport` 를 더한다.

- 내 댓글이고 삭제되지 않았으면: 삭제(destructive)
- 남의 댓글이고 삭제되지 않았으면: 신고
- **삭제된 댓글은 메뉴를 그리지 않는다** — 지금 `isMine && !comment.isDeleted` 조건이 하던 일을 유지한다

`post_comments_page.dart` 의 두 `CommentTile` 호출부(부모 · 답글) 모두에
`onReport` 를 넘긴다. 대상은 `ReportTarget.comment(comment.id)` 다.

문서 주석을 갱신한다.

- [ ] **Step 4: `ProfilePage`**

`AppBar` 에 `actions` 를 더한다. **`isMine` 이 false 이고 프로필이 로드됐을 때만**
`AppOverflowMenu` 를 그린다 — 항목은 신고 하나다.

대상은 `ReportTarget.user(profile.id)` 다. `requestedUserId` 가 아니라 **로드된
프로필의 id** 를 쓴다 — 라우트 파라미터는 신뢰 경계 밖이고, 화면이 실제로 보여주고
있는 사용자를 신고해야 한다.

`AppBar` 는 `_ProfileView.build` 안에 있고 `ProfileState` 는 그 아래
`BlocBuilder` 에서 읽힌다. `actions` 가 `profile` 을 필요로 하므로 `AppBar` 를
`BlocBuilder<ProfileCubit, ProfileState>` 안으로 옮기거나, `context.watch` 로 읽는다.
**기존 상태 전이와 로딩·오류 표시를 깨지 않는 쪽을 고른다.**

- [ ] **Step 5: 테스트**

| 파일 | 검증 |
|---|---|
| `post_tile_test.dart` (신규) | 내 글에는 수정 · 삭제가 뜨고 신고가 **없다** · 남의 글에는 신고가 뜨고 수정 · 삭제가 **없다** · 신고를 고르면 `onReport` 가 불린다 · 콜백이 모두 null 이면 메뉴가 안 그려진다 |
| `post_comments_page_test.dart` | 남의 댓글 메뉴에 신고가 있다 · 내 댓글 메뉴에 삭제가 있고 신고가 없다 · 삭제된 댓글에는 메뉴가 없다 |
| `profile_page_test.dart` | 타인 프로필 AppBar 에 메뉴가 있다 · 내 프로필에는 없다 |

기존 테스트가 삭제 `IconButton` 을 직접 찾고 있으면 메뉴 경로로 고친다 —
**테스트가 깨지는 것이 정상이고, 깨진 것을 고치는 것이 이 스텝의 일이다.**

- [ ] **Step 6: 커밋**

```
feat(safety): 게시물·댓글·프로필에 신고 진입점을 붙인다
```

**Verification:**
- [ ] `cd app && flutter analyze` 에 새 경고가 없다
- [ ] `cd app && flutter test` 전체가 통과한다
- [ ] 내 게시물 · 내 댓글 · 내 프로필에 신고 메뉴가 보이지 않는다
- [ ] 세 진입점이 모두 `AppOverflowMenu` 를 쓴다 (`PopupMenuButton` 직접 사용이 남아 있지 않다)

---

### Task 6: 실제 DB 로 완료 조건 확인 · 문서 갱신

**Files:**
- Create: `docs/features/safety/history.md`
- Create: `docs/testing/features/safety.md`
- Modify: `docs/testing/README.md` (트리 그림과 목록에 safety 추가)
- Modify: `docs/status.md` (2단계의 F7 항목)
- Modify: `docs/features/safety/plan.md` (상태 줄 · 완료 조건 체크)

- [ ] **Step 1: 완료 조건을 실제 DB 로 확인**

[스펙](../../features/safety/plan.md)의 "완료 조건" 9개를 로컬 Supabase 로 직접
확인한다. REST 로 확인하는 것들은 사용자 JWT 가 필요하다 —
`docs/testing/audit-2026-08-24.md` 가 쓴 방법을 그대로 따른다.

| 확인 | 방법 |
|---|---|
| 내 게시물 신고 거부 | 사용자 A 의 JWT 로 A 의 게시물을 신고 → 트리거 문구로 거부 |
| 내 댓글 신고 거부 | 같은 방식 |
| 자기 사용자 신고 거부 | `target_type='user'`, `target_id` = 본인 → `23514` |
| 중복 신고 | 같은 대상 두 번 → `23505` (`reports_once`) |
| 삭제된 게시물 신고 | 소프트 삭제 후 신고 → `신고할 대상이 없습니다` |
| 없는 `target_id` | 임의 uuid → `신고할 대상이 없습니다` |
| `reporter_id` 위조 | 페이로드에 남의 `reporter_id` 를 실어 삽입 → `42501` |
| `status` 위조 | 페이로드에 `status: 'resolved'` → `42501` |
| 남의 신고 조회 | B 의 JWT 로 `select * from reports` → A 의 신고가 안 보인다 |
| 빈 상세 설명 | 앱 경로로는 `null` 이 저장된다 (정규화). REST 로 `''` 를 직접 보내면 `23514` |

**하나라도 기대와 다르면 그 자리에서 고친다.** 이 스텝의 결과를 report 에 표로 적는다.

- [ ] **Step 2: `docs/testing/features/safety.md`**

기존 `docs/testing/features/comment.md` 의 구성을 따른다. 무엇을 어디서
검증하는지(단위 · 위젯 · DB), Step 1 에서 확인한 권한 경계, 실행 명령을 적는다.

- [ ] **Step 3: `docs/testing/README.md`**

트리 그림(12~20행)에 `safety/` 를 더하고, 아래 feature 목록(59~65행)에
safety 항목을 더한다 — 기존 줄들과 같은 형식(`features/safety.md` 를 가리키는 상대 링크)이다.

- [ ] **Step 4: `docs/status.md`**

2단계의 `- [ ] **F7 safety** — 신고 · 차단` 줄을 고친다. **신고만 완료됐고 차단은
남았다**는 것이 드러나야 한다. 예:

두 줄로 나눈다. 완료된 줄은 `[x] **F7 safety (신고)**` 로 시작해 폴리모픽 `reports` ·
대상 검증 트리거 · 게시물·댓글·프로필 진입점을 한 줄로 요약하고, 같은 줄 끝에 계획과
기록으로 가는 상대 링크를 단다 — 2단계의 다른 항목(F5 · F6)이 쓰는 형식 그대로다.
남은 줄은 `[ ] **F7 safety (차단)** — 조회 뷰 두 곳에 양방향 필터` 다.

진행 상태는 **이 문서에만** 적는다.

**주의:** 문서 링크 검사(`app/test/convention/documentation_links_test.dart`)는 코드
펜스 안의 링크도 검사한다. 예시를 적을 때 실제로 존재하지 않는 경로를 링크 문법으로
쓰면 검사가 깨진다.

- [ ] **Step 5: `docs/features/safety/history.md`**

`docs/features/comment/history.md` 의 구성을 따른다. 구현하면서 **계획과 달라진
것**과 **그 이유**가 핵심이다. 계획을 그대로 옮겨 적지 않는다.

- [ ] **Step 6: `docs/features/safety/plan.md` 상태 갱신**

머리말의 `상태: **착수**` 를 `상태: **완료 (신고)**` 로 바꾸고 구현 기록 링크를 단다.
완료 조건 체크박스를 Step 1 의 결과에 맞춰 채운다.

- [ ] **Step 7: 커밋**

```
docs(safety): 신고 구현 결과를 문서에 반영한다
```

**Verification:**
- [ ] Step 1 의 표 10개 항목을 모두 실제로 확인했고 결과를 report 에 적었다
- [ ] `cd app && flutter test test/convention` 이 통과한다 (문서 링크)
- [ ] `cd app && flutter test` 전체가 통과한다
- [ ] `docs/status.md` 에 차단이 남았다는 것이 드러난다
