---
# gstack: design-md-format=spec
name: pawlog
description: 날짜별로 채워지는 산책 수첩. 회백지 위에 리드줄 남색과 테니스공 연두 두 색만 쓰고, 경로 선이 스스로 그려지는 순간 하나에 모션을 몰아준다.
colors:
  paper: "#F4F3EF"
  sheet: "#FBFAF7"
  text: "#24251F"
  text-muted: "#6F6D64"
  rule: "#DDDAD1"
  primary: "#2C3B57"
  on-primary: "#F4F3EF"
  accent: "#CFE04A"
  on-accent: "#2C3B57"
  error: "#B3402E"
  map-bg: "#E9E7E0"
  map-park: "#DCE3D2"
  dark-paper: "#1B1C19"
  dark-sheet: "#23241F"
  dark-text: "#ECEAE3"
  dark-text-muted: "#A19E93"
  dark-rule: "#3A3B35"
  dark-primary: "#A9B8D6"
  dark-on-primary: "#1B1C19"
typography:
  display:
    fontFamily: Gowun Dodum
    fontWeight: 400
    fontSize: 26px
    letterSpacing: -0.01em
  title:
    fontFamily: Gowun Dodum
    fontWeight: 400
    fontSize: 22px
  number-hero:
    fontFamily: Pretendard
    fontWeight: 700
    fontSize: 44px
    letterSpacing: -0.03em
    fontFeature: tnum
  number:
    fontFamily: Pretendard
    fontWeight: 700
    fontSize: 20px
    letterSpacing: -0.01em
    fontFeature: tnum
  body:
    fontFamily: Pretendard
    fontWeight: 400
    fontSize: 15px
    lineHeight: 1.6
  label:
    fontFamily: Pretendard
    fontWeight: 500
    fontSize: 12px
  memo:
    fontFamily: Gaegu
    fontWeight: 400
    fontSize: 20px
    lineHeight: 1.35
rounded:
  photo: 4px
  control: 12px
  sheet: 20px
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 14px
  lg: 20px
  xl: 28px
  2xl: 48px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.full}"
    height: 58px
  button-stop:
    backgroundColor: "{colors.text}"
    textColor: "{colors.paper}"
    rounded: "{rounded.full}"
  tracking-banner:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.control}"
  route-line:
    strokeColor: "{colors.accent}"
    casingColor: "{colors.primary}"
    strokeWidth: 5px
    casingWidth: 9px
  photo:
    rounded: "{rounded.photo}"
  sheet:
    backgroundColor: "{colors.sheet}"
    rounded: "{rounded.sheet}"
---

# pawlog 디자인 시스템

> [pawlog 허브](README.md) · [기획서](overview.md) · [아키텍처](../../../docs/architecture.md)

## Overview

**Creative North Star:** 산책 수첩. 운동 기록 앱이 아니라, 강아지와 걸은 날이 날짜별로
쌓이는 일기장이다.
**Product context:** 강아지 산책을 GPS 로 기록하고 피드로 돌아보는 1인용 모바일 앱(v1 로컬).
비교 대상은 산책 트래커(Tails, Fi + Strava)보다 일기 앱(Day One, Diarly)이다.
**Mode per surface:** 피드·상세 = Read(돌아보기) · 산책 중 = Operate(걸으며 한눈에) ·
저장 폼·반려견 편집 = Operate.
**Reference sites:** [Strava for Dogs 정리](https://trytails.com/guides/dog-health-longevity/strava-for-dogs/) ·
[2026 일기 앱 비교](https://www.holstee.com/blogs/mindful-matter/best-journaling-apps)
**Key characteristics:**
- 카드가 없다. 피드는 왼쪽 큰 날짜 숫자와 세로 '리드줄' 선에 매달린 줄글이다
- 색은 남색과 연두 두 가지뿐이고, 연두는 경로와 '진행 중'에만 나온다
- 사용자가 쓴 메모만 손글씨로 보인다
- 숫자(거리·시간)는 크고 굵고 자리가 흔들리지 않는다

## Colors

**Strategy:** Restrained. 중립색(회백지 · 먹 · 회갈) 위에 동작색 하나(리드줄 남색), 포인트 하나(테니스공 연두).
**Light or dark:** 시스템을 따른다. 낮 산책 야외에서는 라이트가 기본이고, 다크는 '밤산책'
장면을 위한 것이라 먹색 바탕에 남색을 밝게 올리고 연두는 그대로 둔다.

- `primary`(남색)는 누를 수 있는 것: 주 버튼, 진행 배너, 링크 텍스트.
- `accent`(연두)는 버튼·배경·텍스트에 쓰지 않는다. 경로 선, 추적 중 점멸 점, 목표 달성 표시만.
  밝은 지도 위 대비가 약하므로 경로 선은 항상 남색 테두리(casing) 위에 얹는다.
- 중립색은 노란 크림이 아니라 살짝 회색이 도는 종이색이다. 다크 표면은 반전이 아니라
  `dark-paper` < `dark-sheet` 두 단계로 위계를 지킨다.
- `error` 는 삭제 확인과 실패 안내에만.

## Typography

한·영·일 3개 언어를 지원하므로 서체는 한글 글리프 기준으로 고르고, 일본어는 시스템 폰트로 대체된다.

- **고운돋움(Gowun Dodum)** — 화면 제목, 강아지 이름, 상세 제목. 붓 끝이 살짝 남은 둥근 돋움이라
  M3 기본 산세리프와 바로 구별된다. 제목 전용이며 본문에 쓰지 않는다.
- **Pretendard** — 본문·UI·숫자 전부. 숫자는 700 + 타뷸러(`tnum`)로 1초마다 바뀌는
  시간이 좌우로 흔들리지 않게 한다. 히어로 숫자(44)와 본문(15)은 세 배 가까이 차이 나게 둔다.
- **개구(Gaegu)** — 사용자가 쓴 메모에만. 제목·버튼·안내문에 쓰면 장난감처럼 보이므로 금지.
- 로딩: 세 서체 모두 앱 에셋으로 번들한다(로컬 우선 앱이라 첫 실행 오프라인 대비).
  고운돋움·개구는 OFL(Google Fonts), Pretendard 는 OFL(orioncactus/pretendard).

## Layout

- 폰 한 손 기준. 좌우 여백 20, 피드 날짜 열 48 + 간격 14.
- 리듬: 항목 사이 28, 항목 안 요소 사이 8~10. 큰 간격과 작은 간격의 차이로 묶음을 보여준다.
- 사진은 본문 폭을 가득 채운다(4:3). 사진이 없는 기록은 같은 자리에 경로 썸네일.
- 주 동작(산책 시작/끝내기)은 하단 고정 알약 버튼 하나. 다른 동작은 앱바나 줄글 안의 텍스트 버튼.

## Elevation & Depth

평평한 종이가 기본이다. 그림자는 두 곳에만: 하단 주 버튼(아래로 6px, 블러 16)과
지도 위에 올라오는 시트(위로 6px, 블러 18). 카드 그림자, 글로우는 없다. 구분은 `rule` 1px 선으로.

## Shapes

모서리는 역할마다 다르다. 같은 값을 모두에 쓰지 않는다.
- 사진·지도 썸네일 4 — 인화한 사진처럼 거의 각지게
- 입력·배너 12
- 바텀 시트 상단 20
- 주 버튼·토글 알약(full)
- 아바타 원. 여러 마리면 -12 겹치고 바탕색 2px 테두리로 떼어낸다

## Components

- **주 버튼** — 높이 58, 알약, 남색. 누름 시 0.97 축소(120ms ease-out), 비활성은 투명도 0.4.
  로딩↔라벨은 200ms 크로스페이드. 산책 끝내기는 먹색으로 바뀌어 '멈춤'을 색으로 구분한다.
- **피드 항목** — 날짜 열(일 30/700, 요일 12 muted, 아래로 리드줄 1.5px) + 본문 열(아바타·이름·시각
  → 사진 또는 경로 → 거리·시간 → 메모). 같은 날 여러 기록은 날짜를 한 번만 쓰고 리드줄로 잇는다.
  빈 상태는 날짜 열 없이 수첩 첫 장 같은 안내 한 줄 + 산책 시작 버튼.
- **진행 배너** — 남색 바탕, 연두 점 1.6초 점멸, 오른쪽 경과 시간. 탭하면 산책 화면.
- **경로 선** — 남색 casing 9 위에 연두 5, 둥근 끝·둥근 이음.
- **산책 중 시트** — 지도 위로 20 둥근 시트, 숫자 두 개(거리·시간)만 44 크기로.
- **메모** — 개구 20. 빈 메모는 자리를 차지하지 않는다.

## Do's and Don'ts

- Do: 연두는 경로와 '진행 중'에만 쓴다
- Do: 숫자는 Pretendard 700 + tnum
- Do: 화면마다 주 버튼은 하나
- Do: 색·여백·모서리는 테마 토큰에서 읽는다(`Colors.*`, 숫자 리터럴 금지 — 루트 CLAUDE.md UI 규칙)
- Don't: 피드를 카드로 감싸기, 카드 안에 카드
- Don't: 모든 모서리 12 통일
- Don't: 아이콘을 색 동그라미에 넣기, 발바닥 이모지·장식
- Don't: 손글씨를 제목·버튼·시스템 문구에 쓰기
- Don't: 민트·하늘색 '반려동물 앱' 팔레트로 돌아가기

## Motion

- **Approach:** intentional — 평소엔 조용하고, 한 장면에 몰아준다
- **Easing:** enter(ease-out) exit(ease-in) move(ease-in-out, `cubic-bezier(.4,0,.2,1)`)
- **Duration:** 누름 120ms · 상태 전환 200ms · 시트 300ms · 경로 그리기 1600ms
- **The one authored moment:** 산책을 끝내고 저장 화면에 들어가거나 상세를 열 때, 경로 선이
  출발점에서 도착점까지 1.6초에 걸쳐 그려진다. 접근성 설정의 애니메이션 줄이기가 켜져 있으면
  바로 완성된 선을 보여준다.

## Decisions Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-10-04 | 초기 디자인 시스템 작성 | /design-consultation. M3 fromSeed 기본값의 'AI 슬롭' 인상을 벗기 위해 일기 앱 쪽으로 방향을 잡음. 사용자가 고른 핵심 인상은 '따뜻한 산책 일기' |
| 2026-10-04 | 크림+세리프+테라코타 대신 회백지+남색+연두 | 일기 앱의 흔한 공식을 피하고, 리드줄·테니스공이라는 강아지 산책의 사물에서 색을 가져옴 |
| 2026-10-04 | 피드에서 카드 제거 | 날짜 열 + 리드줄 타임라인으로 '수첩'을 한눈에 보이게 함. 구현 비용은 카드보다 큼 |
