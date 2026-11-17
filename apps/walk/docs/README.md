# 걷기(walk) 허브

> [문서 허브](../../../docs/README.md) · [전체 진행 현황](../../../docs/status.md)

생활 도구를 모은 앱 **Life Log** 이다(폴더 · 패키지는 `walk`). 하단 탭 [도구 · 기록 · 물어보기] — 도구는 상단 탭 [알람 · 걷기 · 날씨 · 길찾기], 기록은 [일기 · 지도].

- **걷기** — 오늘 탭은 걸음을 **하루 목표** 링으로, 기록 탭은 주간 · 월간 막대그래프(목표선)로 모아 본다. 걸음은
  폰의 헬스 앱이 **Health Connect** 에 기록한 값을 읽기만 한다.
- **알람** — 기상 알람. `alarm` 패키지로 잠금 화면 위에 울리고, 14일 치를 미리 예약해 두며,
  재부팅 · 시간대 변경 뒤에도 같은 벽시계 시각에 울린다. 알람음은 앱에 든 벨소리(직접 합성) · 기기 알람음 ·
  내 음성 파일(앱 안으로 복사) 중에서 고른다.
- **일기** — SNS 피드처럼 쓰고 읽는 개인 일기장. 글 · 사진 · 30초 이하 영상(압축 사본) · 현재 위치의 장소 이름 · 해시태그를 한 화면에서 붙이고,
  ✨ 를 누르면 글 칸에 쓴 짧은 메모와 사진 촬영 시각으로 초안이 글 칸에 채워진다(물어보기에 연결한 Claude · GPT 의 저가 모델). 기록은 **스토리**(기본 "일상")로 묶이지만 고르는 일은 선택 사항이다.
  피드 카드로 돌아보고 글 · 스토리 · 태그 · 장소로 찾는다.
  지우면 휴지통에 갔다가 기간이 지나면 사라진다. 탭을 PIN · 패턴으로 잠글 수 있다. 데이터는 폰 안(drift + 앱 폴더)에만.
- **날씨** — 지금 위치의 현재 · 시간별(24시간) · 일별(7일) 예보와 "비 언제 와" 한 줄 요약. Open-Meteo(키 없음)에서 받고 마지막 성공을 캐시해 둔다. 일기와 무관.
- **길찾기** — 출발 · 도착을 고르면(현재 위치 · 집/회사 · 자주 간 곳 · 최근 · 역/정류장 검색 · 주소) ODsay 대중교통 경로
  (지하철 · 버스 · 환승)를 총 시간 순으로 보이고, 구간별 상세를 본다. 같은 출발 · 도착은 10분 캐시. API 키가 필요하다([아래](#길찾기-키)).
  예전 통근 탭(집 ↔ 회사 지하철)은 탭에서 빠졌고 코드만 남아 있다.
- **설정** — 걷기(하루 목표) · 일기(잠금 · 다시 잠기는 시간 · 휴지통 기간 · 용량) · 권한 상태 · 테마 · 앱 정보.

로그인 · 백엔드 없음, 안드로이드만. 아이콘과 시작 화면은 초록 바탕 흰 알람시계다
(VectorDrawable, 원본 SVG 는 `assets/icon/`).

코드는 전부 `apps/walk/` 에 있다. commute 와 같이 `lib/` 바로 아래가 계층이다 —
`core/`(앱 셸: `app.dart` · `di/` · 울림 리스너 · 백그라운드 재설정) · `data/` · `domain/` ·
`presentation/`. 계층 아래에 기능 폴더(`walk/` · `alarm/` · `diary/` · `commute/` · `lock/` · `settings/` · `shell/`)를 둔다. 테스트도
`test/` 아래 같은 구조다.

## 길찾기 키

길찾기는 ODsay LAB(lab.odsay.com)의 키가 필요하다(애플리케이션 등록: 플랫폼 Android, 패키지 `com.karma.walk`).
키는 **앱 안에서 입력**한다 — 도구 › 길찾기 ⋮ › 길찾기 키 설정(또는 앱 설정의 길찾기 키 행). 저장 전에 연결을 한 번 확인하고,
키는 보안 저장소(`flutter_secure_storage`)에 두며 마스킹해 보이고 **백업에 넣지 않는다**(복원 뒤 길찾기를 쓴 적이 있고 키가 없으면 다시 넣으라는 안내만 뜬다).

개발용 기본값으로만 빌드 옵션도 쓸 수 있다. 저장된 키가 없을 때 `ODSAY_API_KEY` 를 읽는다. 이때 설정 화면에는 "키 없음"으로 보여도 길찾기는 동작한다.
키 파일은 저장소에 올리지 않는다.

```bash
cd apps/walk
cp config/commute_keys.example.json config/commute_keys.json   # ODSAY_API_KEY 를 채운다(개발용)
flutter run --dart-define-from-file=config/commute_keys.json
```

키가 없으면 길찾기 화면이 키 안내를 보인다. 진행 상황은 [진행 현황](status.md#길찾기).

## 실제 폰에 설치

스토어 배포 없이 APK 를 폰에 바로 깐다. release 빌드는 아직 이 맥의 디버그 키로 서명한다
(`android/app/build.gradle.kts`).

1. **빌드** — `cd apps/walk && flutter build apk --release`(통근 탭을 쓰려면 `--dart-define-from-file=config/commute_keys.json` 추가) →
   `apps/walk/build/app/outputs/flutter-apk/app-release.apk`(약 56MB, 모든 ABI).
2. **옮기기** — 카카오톡 나와의 채팅 · 구글 드라이브 · USB 파일 전송 중 편한 것.
3. **설치** — 폰에서 파일을 연다. 처음 한 번은 그 파일을 연 앱(카카오톡 · 내 파일 · 드라이브)에
   "출처를 알 수 없는 앱 설치"를 허용한다. Play 프로텍트 경고가 뜨면 "무시하고 설치".
4. **첫 실행** — Health Connect 권한을 허용하고(도구 › 걷기 ⋮ › 걷기 설정), 도구 › 알람 ⋮ › 알람 설정의 권한 행에서
   알림 · 정확한 알람 · 전체 화면 알림이 켜져 있는지 본다. Android 13 이하는 Play 스토어에서 Health Connect 앱을 먼저 깐다.

고친 버전도 같은 방법으로 덮어 깔면 알람 · 설정이 남는다. 다른 맥에서 빌드한 APK 는 디버그 키가 달라
덮어 깔 수 없다 — 지우고 다시 깔아야 하고 그때 알람이 사라진다.

## 문서

| 문서 | 단일 진실 소스 |
|---|---|
| [진행 현황](status.md) | 단계별 체크리스트, 다음 할 일 |
| [계획](plan.md) | 화면 · 상태 · 완료 조건 · 범위 밖 |
| [기록](history.md) | 설계 판단 · 최종 리뷰에서 고친 것 · 알려진 한계 |
| [테스트](testing.md) | 파일별 확인 범위 · 기기 시나리오 |
| [설계 — 걷기](../../../docs/superpowers/specs/2026-09-27-walk-app-design.md) | 걷기 결정 기록 · 도메인 · 데이터 · 테스트 |
| [설계 — 알람 · 설정](../../../docs/superpowers/specs/2026-09-27-walk-alarm-design.md) | 알람 결정 · 14일 선예약 sync · 화면 · 권한 |
| [설계 — 남은 시간](../../../docs/superpowers/specs/2026-09-29-walk-alarm-remaining-time-design.md) | 요약 카드 · 남은 시간 · 울림 버튼 |
| [설계 — 시간대](../../../docs/superpowers/specs/2026-09-30-walk-alarm-timezone-design.md) | 시간대 변경 수신기 · 재설정 |
| [설계 — 시각 · 인터랙션 강화](../../../docs/superpowers/specs/2026-10-03-walk-visual-refresh-design.md) | 초록 테마 · 하루 목표 링 · 달성 축하 · 목표선 그래프 · 알람 톤 · 울림 파동 |
| [설계 — 일기](../../../docs/superpowers/specs/2026-10-10-walk-diary-design.md) | 일기 결정 기록 · 스토리 · 휴지통 · 잠금 · 테스트 표 · 스파이크 결과 |
| [설계 — 일기 피드형 작성 · 자동 초안](../../../docs/superpowers/specs/2026-11-15-walk-diary-feed-compose-design.md) | 피드 글쓰기 화면 · 스토리 뒤로 숨기기 · ✨ 초안(문체 · 길이 · 사진 전송 기본 끔 · 저가 모델) · 외부 리뷰 결정 |
| [설계 — 앱 백업 · 복원](../../../docs/superpowers/specs/2026-11-16-walk-diary-backup-design.md) | 영역 선택 백업 · SAF 로컬 zip · 선택 암호화 · 영역별 바꿔 넣기 복원 · 되돌리기 · 자동 백업 규칙 |
| [설계 — 날씨](../../../docs/superpowers/specs/2026-11-14-walk-weather-design.md) | 도구 › 날씨 결정 기록 · Open-Meteo · 위치 · 캐시 규칙 |
| [설계 — 대중교통 길찾기](../../../docs/superpowers/specs/2026-11-17-walk-transit-route-design.md) | 도구 › 길찾기 결정 기록 · ODsay · 키 설정 · 캐시 · 상단 탭 4개 |
| [설계 — 통근 ETA](../../../docs/superpowers/specs/2026-10-21-commute-eta-design.md) | 통근 탭 결정 기록 · 경로 · 실시간 · 판단 · 도착 예상 · 키 |
