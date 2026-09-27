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
