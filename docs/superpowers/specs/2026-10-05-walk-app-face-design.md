# walk — 앱 아이콘 · 스플래시 설계 (알람 고도화 웨이브 2)

> 작성 2026-10-05 · 상태: **설계 승인** · 앱 문서 [walk 허브](../../../apps/walk/docs/README.md) ·
> 백로그 [알람 고도화](2026-10-05-walk-alarm-upgrade-backlog-design.md) F1 · F2

## 1. 출발점

- 런처 아이콘은 Flutter 템플릿 기본 PNG(`mipmap-*/ic_launcher.png`) 그대로다. 적응형 아이콘 · 둥근 아이콘 · 단색 아이콘이 없다.
- 알람 알림의 작은 아이콘도 이 런처 아이콘이다(`alarm` 패키지가 `NotificationSettings.icon` 이 없으면 앱 아이콘을 쓴다).
- 시작 화면은 `launch_background.xml`(흰 바탕 / `?android:colorBackground`)이고 `values-v31` 스플래시 설정이 없다.
- `minSdk = 26` 이라 모든 기기가 적응형 아이콘을 지원한다.

## 2. 결정 기록

| 결정 | 이유 |
|---|---|
| 시안 A(초록 바탕 흰 알람시계 · 노란 종 · 다리 · 발자국) | 사용자 결정 |
| 발자국은 48px 에서도 보이게 키운다(타원 반지름 약 1.3배)고 시계 왼쪽 아래 안전 영역 안에 둔다 | 미리보기에서 점처럼 보였다 |
| 그림은 **VectorDrawable XML** 로 직접 만든다(원 · 선 · 타원뿐이라 손으로 옮길 수 있다). `flutter_launcher_icons` · `flutter_native_splash` 를 쓰지 않는다 | 해상도별 PNG 가 필요 없고 의존성이 늘지 않는다. 원본 SVG 는 `apps/walk/assets/icon/` 에 같이 둔다(문서 · 재생성용, 번들에는 넣지 않음) |
| 적응형 아이콘: `mipmap-anydpi-v26/ic_launcher.xml` · `ic_launcher_round.xml` = 배경 색 `@color/ic_launcher_background`(#1D9E75) + 전경 `@drawable/ic_launcher_foreground` + 단색 `@drawable/ic_launcher_monochrome` | 안드로이드 13 테마 아이콘까지 한 번에. 전경은 108dp 캔버스의 가운데 66dp 안전 원 안에 모든 요소를 둔다 |
| 기존 `mipmap-*/ic_launcher.png` 는 지운다 | minSdk 26 이라 쓰이지 않는다. 남기면 혼동 |
| 알림 작은 아이콘 `@drawable/ic_stat_alarm`(흰 단색 알람시계 실루엣, 24dp)을 만들고 `NotificationSettings.icon: 'ic_stat_alarm'` 으로 넘긴다. 지문에는 넣지 않는다 | 적응형 아이콘을 작은 아이콘으로 쓰면 덩어리로 보인다 |
| 스플래시: 안드로이드 12+ 시스템 스플래시. `values-v31/styles.xml` · `values-night-v31/styles.xml` 의 `LaunchTheme` 에 `windowSplashScreenBackground`(라이트 #1D9E75, 다크 #0F6E56) · `windowSplashScreenAnimatedIcon`(@drawable/splash_icon = 전경과 같은 그림) · `windowSplashScreenIconBackgroundColor` 없음 | 시스템 스플래시는 아이콘 + 단색 배경이 규칙이다 |
| 안드로이드 8~11(minSdk 26~30): `launch_background.xml`(drawable · drawable-v21)을 초록 배경 + 가운데 아이콘 레이어로 바꾼다. 다크 `drawable-night` 도 같은 모양 진한 초록 | 12 미만에서도 같은 첫인상 |
| 첫 프레임 뒤에 앱 안 스플래시(애니메이션 화면)는 두지 않는다 | 알람 울림 화면이 바로 떠야 한다. 지연을 늘리지 않는다 |
| 스플래시에서 앱 테마(NormalTheme)로 넘어갈 때 배경 깜빡임이 없게 `NormalTheme` 의 `windowBackground` 를 `?android:colorBackground` 로 둔다(지금 그대로) | |

## 3. 파일

```
apps/walk/assets/icon/icon.svg            # 원본(마스크 없는 정사각 전체)
apps/walk/assets/icon/foreground.svg      # 108 캔버스 전경
apps/walk/assets/icon/monochrome.svg
android/app/src/main/res/
  mipmap-anydpi-v26/ic_launcher.xml
  mipmap-anydpi-v26/ic_launcher_round.xml
  drawable/ic_launcher_foreground.xml     # VectorDrawable 108x108
  drawable/ic_launcher_monochrome.xml
  drawable/ic_stat_alarm.xml              # 24x24 흰색
  drawable/splash_icon.xml                # 전경과 같은 그림(스플래시 아이콘 규격 288dp 캔버스 중 192 원)
  drawable/launch_background.xml          # 초록 + 아이콘
  drawable-v21/launch_background.xml
  drawable-night/launch_background.xml
  values/colors.xml                       # ic_launcher_background · splash_background(_dark)
  values-v31/styles.xml · values-night-v31/styles.xml
AndroidManifest.xml: android:roundIcon="@mipmap/ic_launcher_round"
```

`assets/icon/` 은 pubspec `assets:` 에 넣지 않는다.

## 4. 그림 좌표 (108 × 108 전경, 가운데 54,54)

미리보기의 120 타일 좌표(가운데 0,0)를 0.9 배해 54,54 로 옮긴다:
다리 선 2개(흰, 굵기 4.5, 둥근 끝) · 종 원 2개(r 9, #FFD27A) · 시계 원(r 28.8, 흰) · 시곗바늘 2개(#0B5D45, 굵기 4.5) ·
발자국 타원 2개(rx 4.1, ry 5.9, #9FE1C9). 모든 요소가 반지름 33 안전 원 안에 든다(구현 때 계산으로 확인).
단색 아이콘은 같은 모양을 한 색(검정, 시스템이 칠함)으로: 시계 원은 테두리 링, 종 · 다리 · 바늘 · 발자국은 채움.

## 5. 확인

- 단위 테스트 없음(리소스). `flutter build apk --debug` 성공.
- 에뮬레이터: 런처(원형 · 둥근 사각 마스크), 테마 아이콘 켜기(13+), 앱 시작 스플래시 라이트/다크, 알람 알림 상태바 아이콘이 흰 실루엣.
- 스크린샷을 남겨 사용자에게 보인다.

## 6. 문서

완료 시 [status](../../../apps/walk/docs/status.md) · `history.md` · `README.md` 를 갱신한다.
