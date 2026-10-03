# W1 dog — 구현 기록

> [pawlog 허브](../../README.md) · [계획](plan.md) · [테스트](testing.md) · [구현 리뷰](../../audits/2026-10-03-implementation-review.md)

설계 판단 · 리뷰에서 고친 것 · 검증 결과를 남긴다. 진행 상태는 [진행 현황](../../status.md)에만 적는다.
구현 커밋은 `cdc1ac2`(단계 ④), 리뷰 반영은 `93d722b` 다.

## 2026-10-03 — 설계 판단

### 사진은 고르는 즉시 파일로 쓰고, 닫힐 때 한 곳에서 정리한다

`DogDraft` 는 바이트가 아니라 `photoPath` 만 든다(리뷰 ① 설계 대비). 저장 버튼에서 파일을
쓰면 저장 실패 · 재시도마다 파일 처리가 섞이므로, `setPhoto` 가 고르는 즉시 `storePhoto` 로
쓰고 폼에는 상대 경로만 넣는다. 버릴 파일은 `DogForm.originalPhotoPath` 하나로 판단한다.

- 다시 고르면 직전 사진이 `originalPhotoPath` 가 아닐 때만 `removePhoto`
- `close()` 에서 저장되지 않았고 `photoPath != originalPhotoPath` 면 `removePhoto`
- 저장에 성공하면 옛 파일은 `SaveDogScenario` 가 DB 성공 뒤 지운다

뒤로 가기 · 삭제 · 저장 실패가 모두 `close()` 한 길을 탄다(리뷰 ④ G). 남는 고아 파일은
"고른 뒤 프로세스가 죽은 경우" 하나이고 v1 은 감수한다.

### `loadFailure` 를 더했다

설계 §4 의 `DogEditState` 에 없던 변형이다. `getDog` 이 `Ok(null)` 이면
`Failure.notFound(targetNotFound)`, `Err` 면 그 실패로 `loadFailure` 가 된다. 빈 폼을 보이면
지워진 강아지를 모르는 사이 새로 만들게 된다. 폼 안의 저장 실패는 계속 `editing.failure` 라
입력이 사라지지 않는다.

### 페이지는 `WalkUseCase` 를 잡지 않는다 — cubit 이 `photoFile` 을 위임한다

목록 · 편집 페이지는 사진 `File` 이 필요하지만 `getIt<WalkUseCase>()` 를 직접 부르지 않는다.
`DogListCubit.photoFile` · `DogEditCubit.photoFile` 이 그 통로다(리뷰 ④ T5,
[아키텍처 ③](../../../../../docs/architecture.md)). 매 빌드 `File` 을 새로 만들지만
`FileImage` 는 경로로 같음을 판단해 다시 디코드하지 않는다.

### `onDone` 의 갈래는 앱이 정한다

페이지는 go_router 를 모르고 `onDone` 한 번만 부른다. 앱 셸의 `finishDogEdit` 이
`markHasDogs()` 뒤 `canPop()` 이면 `pop()`, 아니면 `go('/')` 한다. 첫 실행은 리다이렉트로
`/dogs/new` 가 스택 바닥이라 돌아갈 곳이 없기 때문이다. 삭제 뒤에도 `markHasDogs()` 를
부르지만 무해하다 — 마지막 강아지 삭제는 [기획 §9 남은 판단](../../overview.md#남은-판단-착수-시-결정).

### 목록은 스트림이라 새로고침이 없다

`DogListCubit.start()` 가 `watchDogs()`(이름순 drift watch)를 구독한다. 저장 · 삭제 뒤
목록을 다시 읽지 않는다. `start()` 를 다시 부르면 재구독하므로 실패 화면의 재시도가 같은
메서드다. `close()` 에서 구독을 끊고 모든 `await` 뒤 `isClosed` 를 본다.

### 실패 스낵바는 "새 실패"만 띄운다

`listenWhen` 이 직전 `editing.failure` 와 다를 때만 듣는다. 재빌드마다 같은 스낵바가 뜨지
않는다. 이름 trim 과 빈 이름 검사는 `SaveDogScenario` 몫이라 페이지는 막지 않고
`dogNameRequired` 스낵바로 알린다.

## 리뷰에서 고친 것

소견 원문은 [구현 리뷰](../../audits/2026-10-03-implementation-review.md) ④ 절.

| id | 내용 | 커밋 |
|---|---|---|
| D1 | 강아지 watch 의 매핑 예외가 날 오류로 새던 것을 `handleData` 의 `try/catch` 로 `Err` 로, 생일은 `DateTime.tryParse` | `cdc1ac2` |
| T1 | `setPhoto` 가 `storePhoto` 를 기다리는 사이 저장 · 삭제 · 닫기가 시작되면, 늦게 온 파일을 지우고 상태를 바꾸지 않는다(`_cannotAcceptPhoto`). 직전 파일을 지운 뒤에도 한 번 더 본다 | `93d722b` |
| T2 | 제목 · 더보기 메뉴를 `form?.id` 대신 `dogId != null` 로 정한다. 불러오는 동안 · `loadFailure` 에도 "반려견 수정" | `93d722b` |
| I1 | `setBirthday` · `_withPhoto` 가 생성자를 손으로 다시 부르던 것을 `copyWith` 로(Freezed 센티널로 `null` 도 넣을 수 있다) | `93d722b` |

## 고치지 않았지만 적어 둘 것

- **T1 은 "버린다" 쪽으로 고쳤다.** 사진 파일을 쓰는 동안 저장을 누르면 강아지는 **새 사진
  없이** 저장되고 고른 파일은 지워진다. 고아 파일과 `saved` 뒤 폼 복귀는 막았지만, 사용자는
  사진이 안 바뀐 것을 보고 다시 골라야 한다. 사진 쓰기 동안 저장 버튼을 막는 쪽이 다음 후보다
- 생일을 지우는 UI 가 없다(계획에도 없음, 리뷰 ④ I1)
- 품종이 공백만이면 `"  "` 가 저장된다(리뷰 ① I5 · ④ I4) — trim 을 폼이나 시나리오 한 곳에서
- 아바타 크기에 여백 토큰을 쓴다(`AppSpacing.lg`, `AppSpacing.xl * 2`, 리뷰 ④ T3) — `AppAvatar`
  크기 프리셋은 설계 §7 후보
- 로딩이 맨 `CircularProgressIndicator` 다(리뷰 ④ I3) — 공통 로딩 위젯 승격 후보
- 마지막 강아지 삭제를 막지 않는다. W2 의 0마리 안내가 받는데, 안내에서 등록하고 돌아와도
  갱신되지 않던 V2 는 `d5f95b0` 에서 고쳤다([tracking 기록](../tracking/history.md))
- **테스트 공백**(리뷰 ④ I2): `setPhoto` 실패 스낵바, `delete` 실패, `load` 의 `Err`, 수정 폼에서
  새 사진을 고른 뒤 닫을 때 **원래 사진이 남는지**(지금은 신규 폼만), 페이지의 사진 버튼 흐름
  (`prepare` 예외 → 스낵바), `loadFailure` 일 때의 제목

## 검증

- `93d722b` 스냅숏에서 `feature_walk` `flutter analyze` 0건 · `flutter test` `+150`(W1 몫 23건 —
  cubit 14 · 페이지 9), `apps/pawlog` `+5`(리다이렉트 4 · 경계 1)
- 리뷰어가 `cdc1ac2` 를 따로 꺼내 `+77` · analyze 0건 · `Colors.` / `BorderRadius.circular` /
  숫자 여백 / `.when(` grep 0건을 확인했다
- **에뮬레이터 확인은 아직 하지 않았다 (이 환경에 Android SDK 없음).** 완료 조건의 화면 확인
  (등록 → 목록 → 수정 → 삭제, 첫 실행 흐름, 사진 파일 정리)은 [테스트](testing.md#에뮬레이터)에
  미실행으로 남겼다. iOS 도 빌드하지 않았다
