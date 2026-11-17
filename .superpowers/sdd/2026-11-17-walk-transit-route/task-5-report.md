# Task 5 보고

구현: `lib/domain/transit/usecase/transit_point_suggestions.dart` (`@injectable` TransitPointSuggestions + TransitSuggestions), DI 재생성(injection.config.dart).
- home/work: PlaceRepository.load → TransitPoint(source home/work). recent: RecentPoints.load.
- frequent: hasAnyPoint 확인 → 최근 30일 pointsAround → TrackAnalyzer(openEnd 는 recorder.status 로 stayOpenEnd, status 실패 시 null) → frequentPlaces(limit 5) → StayNamer 이름. 이름이 null 인 곳은 제외. 어떤 예외든 빈 목록.
- saveAs: Place(kind, lat, lng, label) 로 PlaceRepository.save.
- location_tools 는 건드리지 않음(공유 헬퍼 추출 없이 계산을 복제; 약 20줄).

## TDD
RED: `flutter test test/domain/transit/usecase/transit_point_suggestions_test.dart` → "'TransitPointSuggestions' isn't a type" (구현 전 예상된 실패).
GREEN: 7/7 passing. 전체 `flutter test` 4271 통과 / analyze 무이슈.

## 판단 · 우려
- "recorder off" 는 location_tools 와 같이 빈 목록의 사유가 아님: 점이 없을 때만 빈 목록, 꺼져 있어도 저장된 점으로 계산(openEnd 만 없음). 브리프의 "recorder off or no points" 를 "점 없음" 으로 해석.
- 이름 못 얻은 장소는 라벨이 없어 제외(오프라인이면 frequent 가 빌 수 있음).
- LocationSync(수거)는 생성자에 없어 부르지 않음 — 브리프 시그니처 그대로.
- 이름 조회 시간 예산(location_tools 의 10초)은 5곳 상한이라 생략.
