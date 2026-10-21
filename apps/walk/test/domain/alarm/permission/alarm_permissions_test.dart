import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission/permission.dart';
import 'package:walk/domain/alarm/permission/alarm_permissions.dart';

class _MockRequester extends Mock implements PermissionRequester {}

void main() {
  late _MockRequester notification;
  late _MockRequester exactAlarm;
  late AlarmPermissions permissions;

  setUp(() {
    notification = _MockRequester();
    exactAlarm = _MockRequester();
    permissions = AlarmPermissions(
      notification: notification,
      exactAlarm: exactAlarm,
      fullScreenIntent: _MockRequester(),
    );
  });

  test('ensureForAlarm 은 알림 → 정확한 알람 순서로 확인한다', () async {
    when(
      () => notification.ensure(),
    ).thenAnswer((_) async => PermissionStatus.denied);
    when(
      () => exactAlarm.ensure(),
    ).thenAnswer((_) async => PermissionStatus.granted);

    await permissions.ensureForAlarm();

    verifyInOrder([() => notification.ensure(), () => exactAlarm.ensure()]);
  });

  test('canRing 은 둘 다 허용일 때만 true', () async {
    when(
      () => notification.check(),
    ).thenAnswer((_) async => PermissionStatus.granted);
    when(
      () => exactAlarm.check(),
    ).thenAnswer((_) async => PermissionStatus.granted);
    expect(await permissions.canRing(), isTrue);

    when(
      () => exactAlarm.check(),
    ).thenAnswer((_) async => PermissionStatus.denied);
    expect(await permissions.canRing(), isFalse);

    when(
      () => exactAlarm.check(),
    ).thenAnswer((_) async => PermissionStatus.granted);
    when(
      () => notification.check(),
    ).thenAnswer((_) async => PermissionStatus.permanentlyDenied);
    expect(await permissions.canRing(), isFalse);
  });
}
