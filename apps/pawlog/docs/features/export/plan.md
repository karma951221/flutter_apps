# W8 export — 계획 (화면 · 상태 · 완료 조건)

> [pawlog 허브](../../README.md) · [기획 §3](../../overview.md#3-mvpv1-범위) · [W3 record](../record/plan.md)

> 상태: 착수 2026-10-17 · 진행 상태의 단일 기준은 [진행 현황](../../status.md)

## 범위

산책 **한 건을 GPX 1.1 파일로 내보내 공유 시트로 넘긴다**. 기획서 §3 이 v1 밖으로 뺀 "데이터 내보내기" 의
첫 조각이다. 로컬에만 저장하는 앱이라 경로를 밖으로(Strava · 지도 앱 · 백업) 꺼낼 길이 없었다.
사용자가 "묻지 말고 알아서 진행" 이라고 해서 오케스트레이터가 골랐다. 전체 백업 · 가져오기 · 사진 동봉은 범위 밖.

## 결정

| # | 결정 | 근거 |
|---|---|---|
| 1 | 입구는 상세 화면 더보기 메뉴의 "GPX로 내보내기" 한 줄 | 산책 한 건을 보고 있을 때 나오는 동작. 화면당 주 버튼 규칙을 건드리지 않는다 |
| 2 | GPX 는 도메인 순수 함수 `GpxEncoder.encode(...)` 가 만든다 | 위젯 · 플러그인 없이 테스트한다 |
| 3 | 파일 쓰기 · 공유는 도메인 인터페이스 `WalkFileSharer` 뒤 `share_plus` 구현 | 페이지 · cubit 테스트가 플랫폼 없이 돈다 |
| 4 | 경로 점이 없으면 메뉴는 그대로 두고 누르면 스낵바 "경로가 없어 내보낼 수 없어요" | 메뉴 항목이 나타났다 사라지는 것보다 이유를 알려 주는 편이 낫다 |
| 5 | 일시정지 구간은 나누지 않고 `trkseg` 하나 | W7 도 경로 선을 끊지 않았다. 점마다 시각이 있어 받는 앱이 멈춤을 알 수 있다 |
| 6 | 트랙 이름 = 반려견 이름을 `, ` 로 이은 것, 메모는 `<desc>`, 파일 이름 `pawlog-yyyy-MM-dd-HHmm.gpx`(현지 시작 시각) | 언어와 무관하고 겹치지 않는다 |

## GPX 형태

```xml
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="pawlog" xmlns="http://www.topografix.com/GPX/1/1">
  <metadata><name>콩이, 보리</name><time>2026-10-17T00:12:00Z</time></metadata>
  <trk>
    <name>콩이, 보리</name>
    <desc>공원 한 바퀴</desc>
    <type>walking</type>
    <trkseg>
      <trkpt lat="37.566500" lon="126.978000"><time>2026-10-17T00:12:03Z</time></trkpt>
    </trkseg>
  </trk>
</gpx>
```

시각은 UTC `Z`, 좌표는 소수 6자리, 이름 · 메모는 XML 이스케이프(`& < > " '`). 메모가 없으면 `<desc>` 를 쓰지 않는다.

## 화면 · 상태

`WalkDetailState` 는 그대로다. `WalkDetailCubit.exportGpx()` 가 `Future<WalkExportResult>` 를 돌려주고, 페이지가 결과로 스낵바를 띄운다.

| 결과 | 화면 |
|---|---|
| 공유 시트가 열림(공유 · 취소 모두) | 아무것도 안 띄움 |
| 경로 없음 | `AppSnackBar` `walkExportNoRoute` |
| 실패(파일 쓰기 · 플러그인 오류) | `AppSnackBar` `walkExportFailed` |

## 문자열 (ko 템플릿 · en · ja)

| 키 | ko | en | ja |
|---|---|---|---|
| `walkExportGpx` | GPX로 내보내기 | Export GPX | GPXで書き出す |
| `walkExportNoRoute` | 경로가 없어 내보낼 수 없어요 | There's no route to export | 書き出せる経路がありません |
| `walkExportFailed` | 내보내지 못했어요 | Couldn't export the walk | 書き出せませんでした |

## 완료 조건

- [ ] `GpxEncoder` 단위 테스트(형태 · 이스케이프 · 메모 없음 · 점 없음 · UTC · 소수 6자리)
- [ ] cubit · 페이지 테스트(메뉴 항목 · 세 결과 · 공유에 넘긴 파일 이름 · 내용)
- [ ] `flutter analyze` 0 · `flutter test` · `flutter build apk --debug`
- [ ] 에뮬레이터: 상세 → 더보기 → GPX로 내보내기 → 공유 시트가 뜬다 · 점 없는 산책은 스낵바
