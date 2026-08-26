# theme — 구현 기록 (다크모드)

> [계획](plan.md) · [테스트](../../testing/features/theme.md)

구현 2026-08-26 (commit `cb7472d`). 계획과 달라진 것과 그 이유만 적는다.

## 계획에 없던 변경 두 가지

**`configureDependencies()` 가 `await getIt.init()` 으로 바뀌었다.** 계획은 "부트스트랩
변경 없음"이라고 했지만, `@preResolve` 를 쓰는 순간 생성된 `init` 의 반환이
`Future<GetIt>` 이 된다. await 없이 두면 첫 화면이 `SharedPreferences` 등록보다 먼저
그것을 요구하는 경쟁이 생긴다. 호출부 세 곳(bootstrap 두 경로 · Patrol 하니스)이
이미 전부 await 하고 있어 외부 동작은 그대로다 — 리뷰가 세 호출부를 확인했다.

**`home_shell_page_test.dart` 에 `ThemeCubit` 제공이 추가됐다.** 설정 탭이 이제
`ThemeCubit` 을 읽으므로 홈 셸 테스트의 하니스에도 프로덕션(`app.dart`)과 같은
모양으로 넣어야 했다.

## 계획대로였지만 적어둘 것

- **scenario 디렉터리가 없다.** facade 가 repository 로 바로 위임한다 — 정책도,
  저장소 조합도 없는 feature 라 scenario 를 만들면 빈 통과 계층만 는다.
- **첫 프레임 무깜빡임**은 계획의 기제 그대로 성립한다: `@preResolve` 로
  `SharedPreferences` 가 DI 시점에 준비되고, cubit 생성자가 `super()` 초기화식에서
  동기로 읽으므로 `MaterialApp` 의 첫 build 가 이미 저장된 모드다. 리뷰가 경로
  전체를 추적해 확인했다.

## 부수 발견

`AppColors.like` · `dislike` 가 **어디에서도 쓰이지 않는다** (lib · test 0건).
반응 UI 는 `AppCountAction` 이 `colorScheme` 파생 색으로 그린다. 죽은 토큰이라
다크 대비 문제도 없다 — 지울지는 별도 판단으로 남긴다. 만약 되살려 작은 글자에
쓴다면 `like`(다크 표면 대비 ~3.5:1)는 WCAG AA 에 걸린다.
