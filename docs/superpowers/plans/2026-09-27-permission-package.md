# permission 패키지 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `packages/permission`(상태 enum · source 인터페이스 · 세션당 1회 요청 정책)을 만들고 commute 위치 권한을 그 위로 옮긴다.

**Architecture:** 패키지는 외부 pub 의존 없는 Flutter 패키지. 앱은 플러그인(geolocator · health)으로 `PermissionSource` 를 구현하고 `PermissionRequester` 로 요청 정책을 공유한다.

**Tech Stack:** Dart 3.11 · Flutter · pub workspace · mocktail(commute 테스트)

**Spec:** [docs/superpowers/specs/2026-09-27-permission-package-design.md](../specs/2026-09-27-permission-package-design.md)

## Global Constraints

- 패키지 이름 `permission`, 경로 `packages/permission`, `resolution: workspace`, `environment.sdk: ^3.11.5`
- 패키지 의존: `flutter` SDK 뿐. dev: `flutter_lints: ^6.0.0` · `flutter_test`
- `analysis_options.yaml` 은 `include: ../../analysis_options.yaml`
- **git 커밋 · `git add` 하지 않는다.** 인덱스에 다른 작업이 스테이징돼 있다
- walk 앱 코드와 walk 문서는 건드리지 않는다(다른 세션이 작업 중)

---

### Task 1: permission 패키지

**Files:**
- Create: `packages/permission/pubspec.yaml`, `packages/permission/analysis_options.yaml`
- Create: `packages/permission/lib/permission.dart`
- Create: `packages/permission/lib/src/permission_status.dart`, `permission_source.dart`, `permission_requester.dart`
- Test: `packages/permission/test/permission_requester_test.dart`
- Modify: 루트 `pubspec.yaml` `workspace:` 에 `packages/permission` 추가(알파벳 순, `packages/l10n` 뒤)

**Interfaces — Produces:**

```dart
enum PermissionStatus { granted, denied, permanentlyDenied }

abstract interface class PermissionSource {
  Future<PermissionStatus> check();
  Future<PermissionStatus> request();
  Future<void> openSettings();
}

class PermissionRequester {
  PermissionRequester(PermissionSource source);
  bool get declinedThisSession;
  Future<PermissionStatus> check();
  Future<PermissionStatus> ensure();
  Future<PermissionStatus> requestAgain();
  Future<void> openSettings();
}
```

- [ ] **Step 1: 패키지 뼈대**

`pubspec.yaml`:

```yaml
name: permission
description: Shared runtime permission status and request policy.
publish_to: none
resolution: workspace

environment:
  sdk: ^3.11.5

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_lints: ^6.0.0
  flutter_test:
    sdk: flutter
```

`lib/permission.dart`:

```dart
export 'src/permission_requester.dart';
export 'src/permission_source.dart';
export 'src/permission_status.dart';
```

루트 `pubspec.yaml` workspace 에 추가 후 루트에서 `flutter pub get`.

- [ ] **Step 2: 실패하는 테스트**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:permission/permission.dart';

class _FakeSource implements PermissionSource {
  _FakeSource(this.status, {PermissionStatus? onRequest})
    : onRequest = onRequest ?? status;

  PermissionStatus status;
  PermissionStatus onRequest;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<PermissionStatus> check() async => status;

  @override
  Future<PermissionStatus> request() async {
    requests++;
    status = onRequest;
    return onRequest;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

void main() {
  test('허용 상태면 ensure 가 요청하지 않는다', () async {
    final source = _FakeSource(PermissionStatus.granted);
    final requester = PermissionRequester(source);

    expect(await requester.ensure(), PermissionStatus.granted);
    expect(source.requests, 0);
  });

  test('영구 거부면 ensure 가 요청하지 않는다', () async {
    final source = _FakeSource(PermissionStatus.permanentlyDenied);
    final requester = PermissionRequester(source);

    expect(await requester.ensure(), PermissionStatus.permanentlyDenied);
    expect(source.requests, 0);
  });

  test('거부 상태는 한 번 요청하고, 거부되면 같은 세션에서 다시 묻지 않는다', () async {
    final source = _FakeSource(PermissionStatus.denied);
    final requester = PermissionRequester(source);

    expect(await requester.ensure(), PermissionStatus.denied);
    expect(requester.declinedThisSession, isTrue);
    expect(await requester.ensure(), PermissionStatus.denied);
    expect(source.requests, 1);
  });

  test('요청에서 허용되면 거부로 기억하지 않는다', () async {
    final source = _FakeSource(
      PermissionStatus.denied,
      onRequest: PermissionStatus.granted,
    );
    final requester = PermissionRequester(source);

    expect(await requester.ensure(), PermissionStatus.granted);
    expect(requester.declinedThisSession, isFalse);
  });

  test('거부한 뒤 설정에서 허용하면 ensure 가 묻지 않고 허용을 돌려준다', () async {
    final source = _FakeSource(PermissionStatus.denied);
    final requester = PermissionRequester(source);
    await requester.ensure();

    source.status = PermissionStatus.granted;

    expect(await requester.ensure(), PermissionStatus.granted);
    expect(source.requests, 1);
  });

  test('requestAgain 은 세션 기억과 무관하게 매번 요청한다', () async {
    final source = _FakeSource(PermissionStatus.denied);
    final requester = PermissionRequester(source);
    await requester.ensure();

    await requester.requestAgain();
    await requester.requestAgain();

    expect(source.requests, 3);
    expect(requester.declinedThisSession, isTrue);
  });

  test('requestAgain 으로 허용되면 거부 기억을 지운다', () async {
    final source = _FakeSource(PermissionStatus.denied);
    final requester = PermissionRequester(source);
    await requester.ensure();

    source.onRequest = PermissionStatus.granted;

    expect(await requester.requestAgain(), PermissionStatus.granted);
    expect(requester.declinedThisSession, isFalse);
  });

  test('check 는 요청하지 않는다', () async {
    final source = _FakeSource(PermissionStatus.denied);
    final requester = PermissionRequester(source);

    expect(await requester.check(), PermissionStatus.denied);
    expect(source.requests, 0);
  });

  test('openSettings 는 source 로 위임한다', () async {
    final source = _FakeSource(PermissionStatus.denied);
    await PermissionRequester(source).openSettings();

    expect(source.settingsOpened, 1);
  });
}
```

- [ ] **Step 3: 실패 확인** — `cd packages/permission && flutter test` → 컴파일 실패(타입 없음)

- [ ] **Step 4: 구현**

`permission_status.dart`:

```dart
/// 런타임 권한 상태. 요청 API 는 앱마다 다르므로(geolocator · health)
/// 각 앱의 [PermissionSource] 가 이 값으로 바꿔 준다.
enum PermissionStatus {
  granted,
  denied,

  /// 플랫폼이 더 이상 다이얼로그를 띄우지 않는다고 알려준 상태.
  /// 알려주지 않는 플랫폼(Health Connect)은 [denied] 로 둔다.
  permanentlyDenied,
}
```

`permission_source.dart`:

```dart
import 'permission_status.dart';

/// 권한 하나를 확인 · 요청하는 플랫폼 경계. 앱이 플러그인으로 구현한다.
abstract interface class PermissionSource {
  Future<PermissionStatus> check();

  Future<PermissionStatus> request();

  Future<void> openSettings();
}
```

`permission_requester.dart`:

```dart
import 'permission_source.dart';
import 'permission_status.dart';

/// 세션당 한 번만 묻는 요청 정책. Android 는 첫 거부 뒤에도 `denied` 를
/// 돌려주므로, 기억해 두지 않으면 새로고침마다 시스템 다이얼로그가 다시 뜬다.
/// 인스턴스가 기억을 가지므로 앱 수명 동안 하나만 둔다.
class PermissionRequester {
  PermissionRequester(this._source);

  final PermissionSource _source;
  bool _declined = false;

  /// 이번 세션에서 요청 결과가 허용이 아니었는지.
  bool get declinedThisSession => _declined;

  Future<PermissionStatus> check() => _source.check();

  /// 거부 상태이고 이번 세션에 아직 거부하지 않았으면 한 번 요청한다.
  Future<PermissionStatus> ensure() async {
    final status = await _source.check();
    if (status != PermissionStatus.denied || _declined) return status;
    return _request();
  }

  /// 사용자가 직접 허용을 눌렀을 때. 세션 기억과 무관하게 요청한다.
  Future<PermissionStatus> requestAgain() => _request();

  Future<void> openSettings() => _source.openSettings();

  Future<PermissionStatus> _request() async {
    final status = await _source.request();
    _declined = status != PermissionStatus.granted;
    return status;
  }
}
```

- [ ] **Step 5: 통과 확인** — `cd packages/permission && flutter test && flutter analyze` → 모두 통과, 이슈 0

---

### Task 2: commute 위치 권한을 permission 패키지로

**Files:**
- Modify: `apps/commute/pubspec.yaml` — dependencies 에 `permission: any` (`l10n: any` 뒤)
- Modify: `apps/commute/lib/data/location/location_gateway.dart` — `openAppSettings()` 추가
- Create: `apps/commute/lib/data/location/geolocator_permission_source.dart`
- Modify: `apps/commute/lib/data/repository/geolocator_location_repository.dart`
- Test: `apps/commute/test/data/location/geolocator_permission_source_test.dart` (새로)
- Test: `apps/commute/test/data/repository/geolocator_location_repository_test.dart` (의미 변경 없이 통과해야 함)

**Interfaces — Consumes:** Task 1 의 `PermissionStatus` · `PermissionSource` · `PermissionRequester`.

- [ ] **Step 1: gateway 에 설정 열기 추가**

```dart
  Future<bool> openAppSettings();
```

`GeolocatorGateway`:

```dart
  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
```

- [ ] **Step 2: 실패하는 매핑 테스트** (`test/data/location/geolocator_permission_source_test.dart`)

```dart
import 'package:commute/data/location/geolocator_permission_source.dart';
import 'package:commute/data/location/location_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';

class _MockLocationGateway extends Mock implements LocationGateway {}

void main() {
  late _MockLocationGateway gateway;
  late GeolocatorPermissionSource source;

  setUp(() {
    gateway = _MockLocationGateway();
    source = GeolocatorPermissionSource(gateway);
  });

  const cases = {
    LocationPermission.always: PermissionStatus.granted,
    LocationPermission.whileInUse: PermissionStatus.granted,
    LocationPermission.denied: PermissionStatus.denied,
    LocationPermission.unableToDetermine: PermissionStatus.denied,
    LocationPermission.deniedForever: PermissionStatus.permanentlyDenied,
  };

  for (final MapEntry(key: platform, value: expected) in cases.entries) {
    test('check: $platform → $expected', () async {
      when(() => gateway.checkPermission()).thenAnswer((_) async => platform);
      expect(await source.check(), expected);
    });

    test('request: $platform → $expected', () async {
      when(() => gateway.requestPermission()).thenAnswer((_) async => platform);
      expect(await source.request(), expected);
    });
  }

  test('openSettings 는 앱 설정을 연다', () async {
    when(() => gateway.openAppSettings()).thenAnswer((_) async => true);
    await source.openSettings();
    verify(() => gateway.openAppSettings()).called(1);
  });
}
```

`cd apps/commute && flutter test test/data/location` → 컴파일 실패 확인.

- [ ] **Step 3: source 구현**

```dart
import 'package:geolocator/geolocator.dart';
import 'package:permission/permission.dart';

import 'location_gateway.dart';

class GeolocatorPermissionSource implements PermissionSource {
  GeolocatorPermissionSource(this._gateway);

  final LocationGateway _gateway;

  @override
  Future<PermissionStatus> check() async =>
      _map(await _gateway.checkPermission());

  @override
  Future<PermissionStatus> request() async =>
      _map(await _gateway.requestPermission());

  @override
  Future<void> openSettings() => _gateway.openAppSettings();

  static PermissionStatus _map(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.always ||
        LocationPermission.whileInUse => PermissionStatus.granted,
        LocationPermission.deniedForever => PermissionStatus.permanentlyDenied,
        LocationPermission.denied ||
        LocationPermission.unableToDetermine => PermissionStatus.denied,
      };
}
```

- [ ] **Step 4: 저장소를 requester 로**

`GeolocatorLocationRepository` 는 `@LazySingleton` 이라 requester 를 필드로 둔다.
생성자 시그니처(`GeolocatorLocationRepository(LocationGateway)`)는 그대로라 DI 재생성과
기존 테스트 셋업 변경이 필요 없다.

```dart
@LazySingleton(as: LocationRepository)
class GeolocatorLocationRepository implements LocationRepository {
  GeolocatorLocationRepository(this._gateway)
    : _permission = PermissionRequester(GeolocatorPermissionSource(_gateway));

  final LocationGateway _gateway;

  /// 세션당 한 번만 묻는다. 거부는 정상 분기라 조용히 fallback 으로 보낸다.
  final PermissionRequester _permission;

  @override
  Future<Result<GeoPoint>> currentLocation({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      if (!await _gateway.isLocationServiceEnabled()) {
        return const Err(
          Failure.validation(failureCode: FailureCode.locationServiceDisabled),
        );
      }

      if (await _permission.ensure() != PermissionStatus.granted) {
        return const Err(
          Failure.forbidden(failureCode: FailureCode.locationPermissionDenied),
        );
      }

      final position = await _gateway.getCurrentPosition(timeout: timeout);
      return Ok(GeoPoint(lat: position.latitude, lng: position.longitude));
    } on TimeoutException {
      // 기존 그대로
    } catch (error) {
      // 기존 그대로
    }
  }
}
```

import 에 `package:permission/permission.dart` 와 `../location/geolocator_permission_source.dart` 를
더하고, 더 쓰지 않는 `package:geolocator/geolocator.dart` import 는 지운다.

- [ ] **Step 5: 확인**

`cd apps/commute && flutter test && flutter analyze` → 기존 `geolocator_location_repository_test.dart` 8개를 포함해 모두 통과, 이슈 0.
`injection.config.dart` 는 생성자 시그니처가 같으므로 바뀌지 않아야 한다(바뀌면 build_runner 로 재생성).

---

### Task 3: 문서 (직접)

- `docs/architecture.md` 트리의 `packages/` 에 `permission/` 한 줄
- `docs/dependencies.md` 그래프에 `commute_app --> PERM`
- `docs/status.md` 에 permission 패키지 완료 한 줄
- `apps/commute/docs/history.md` 에 리팩터링 한 줄

### Task 4: walk 세션에 알림 (직접)

walk 세션(`local_910f164f-...`)에 API · 적용 방법(spec §4 walk)을 보낸다. walk 설계 문서 반영은 그 세션이 한다.
