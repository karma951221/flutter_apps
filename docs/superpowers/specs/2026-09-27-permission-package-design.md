# permission 패키지 설계

> 작성 2026-09-27 · 상태: **승인** · 관련 [walk 설계](2026-09-27-walk-app-design.md) · [아키텍처](../../architecture.md)

## 1. 목적

commute(위치)와 walk(Health Connect)가 둘 다 런타임 권한을 받는다. 권한을 요청하는 API는
앱마다 다르지만(`geolocator` · `health`), **상태 모델**과 **"이번 세션에서 한 번 거부하면
다시 묻지 않는" 요청 정책**은 같다. 이 둘만 `packages/permission` 으로 뺀다.

## 2. 결정 기록

| 결정 | 이유 |
|---|---|
| 순수 Dart, 의존 없음 | 권한 요청 자체는 앱별 플러그인이 한다. Health Connect 권한은 `permission_handler` 로 받을 수 없다 |
| 위젯은 넣지 않는다 | 안내 화면은 각 앱이 `AppPlaceholder` 로 만든다. 두 앱이 같은 모양을 쓰게 되면 그때 올린다 |
| 서비스 꺼짐 · 미설치는 넣지 않는다 | 위치 서비스 off, Health Connect 미설치 · 업데이트 필요는 권한이 아니다. 각 앱에 남긴다 |
| `permanentlyDenied` 는 플랫폼이 알려줄 때만 | geolocator 는 `deniedForever` 를 주지만 Health Connect 는 두 번 거부하면 다이얼로그를 조용히 생략할 뿐 구분해 주지 않는다. 그 경우 앱은 `denied` + `declinedThisSession` 으로 "설정 열기"를 보인다 |

## 3. API

```
packages/permission/          name: permission, resolution: workspace
  lib/permission.dart         export
  lib/src/permission_status.dart
  lib/src/permission_source.dart
  lib/src/permission_requester.dart
  test/permission_requester_test.dart
```

```dart
enum PermissionStatus { granted, denied, permanentlyDenied }

abstract interface class PermissionSource {
  Future<PermissionStatus> check();
  Future<PermissionStatus> request();
  Future<void> openSettings();
}

class PermissionRequester {
  PermissionRequester(PermissionSource source);

  /// 이번 세션에서 request 결과가 granted 가 아니었는지.
  bool get declinedThisSession;

  /// 확인만 한다. 다이얼로그 없음.
  Future<PermissionStatus> check();

  /// check 가 denied 이고 이번 세션에 아직 거부하지 않았으면 request 를 한 번 한다.
  /// granted · permanentlyDenied 면 묻지 않는다.
  Future<PermissionStatus> ensure();

  /// 사용자가 "권한 허용" 버튼을 눌렀을 때. 세션 기억과 무관하게 request 한다.
  Future<PermissionStatus> requestAgain();

  Future<void> openSettings();
}
```

`PermissionRequester` 는 인스턴스가 세션 기억을 가지므로 앱 수명 동안 하나만 둔다
(싱글턴 저장소의 필드로 두거나 앱 DI 에 등록). 패키지는 injectable 에 의존하지 않는다.
melos 스크립트가 `--flutter` 로 거르므로 pubspec 은 `flutter` SDK 와 `flutter_test` 만 둔다
(외부 pub 패키지 없음).

## 4. 앱 적용

### commute (지금)

- `data/location/geolocator_permission_source.dart` — `LocationGateway` 의
  `checkPermission` / `requestPermission` 을 `PermissionStatus` 로 매핑한다
  (`always` · `whileInUse` → granted, `denied` · `unableToDetermine` → denied,
  `deniedForever` → permanentlyDenied). `openSettings` 는 `Geolocator.openAppSettings`
  (gateway 에 메서드 추가).
- `GeolocatorLocationRepository` 의 `_requestDeclined` 필드를 `PermissionRequester.ensure()`
  로 바꾼다. 서비스 꺼짐 · 타임아웃 · `FailureCode` 매핑 등 나머지 동작은 그대로다.
- 기존 `geolocator_location_repository_test.dart` 가 의미를 바꾸지 않고 통과해야 한다
  (생성자 주입이 바뀌면 테스트 셋업만 고친다).

### walk (구현 3 · 4단계에서)

- `data/health/health_permission_source.dart` — `health` 의 `hasPermissions` /
  `requestAuthorization` 을 매핑. 걸음 권한 기준. `openSettings` 는 Health Connect 설정 화면.
- `HealthAccess` enum 은 그대로 두고, `permissionDenied` 판정만 requester 를 거친다.
- 권한 없음 화면: 버튼은 `requestAgain()`. `declinedThisSession` 이거나 `permanentlyDenied`
  면 "설정 열기" 버튼을 함께 보인다.

## 5. 테스트

`permission_requester_test.dart` — 가짜 source 로:

- check 가 granted 면 ensure 가 request 하지 않는다
- permanentlyDenied 면 ensure 가 request 하지 않는다
- denied → ensure 가 request 를 한 번 하고, 거부되면 `declinedThisSession` true, 두 번째 ensure 는 request 하지 않는다
- request 가 granted 면 `declinedThisSession` false
- requestAgain 은 세션 기억과 무관하게 매번 request 한다
- openSettings 는 source 로 위임

commute 는 기존 저장소 테스트 + `GeolocatorPermissionSource` 매핑 테스트.

## 6. 범위 밖

UI 위젯 · `permission_handler` · iOS · 알림 · 카메라 등 다른 권한 종류(필요해지면 source 구현만 더한다).
