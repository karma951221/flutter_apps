import 'package:freezed_annotation/freezed_annotation.dart';

part 'lock_config.freezed.dart';

/// 일기 잠금 방식(스펙 §7). PIN 은 4자리, 패턴은 점 4개 이상.
enum LockMethod { pin, pattern }

/// 앱이 백그라운드로 간 뒤 다시 잠기기까지의 시간.
enum RelockDelay {
  immediate(Duration.zero),
  seconds30(Duration(seconds: 30)),
  minute1(Duration(minutes: 1)),
  minutes5(Duration(minutes: 5));

  const RelockDelay(this.duration);

  final Duration duration;

  static const fallback = RelockDelay.minute1;
}

/// 일기 잠금 설정. 비밀(해시 · salt)은 여기 없다 — `LockRepository` 가 따로 가진다.
@freezed
class LockConfig with _$LockConfig {
  @override
  final bool enabled;

  @override
  final LockMethod method;

  @override
  final RelockDelay relockDelay;

  const LockConfig({
    this.enabled = false,
    this.method = LockMethod.pin,
    this.relockDelay = RelockDelay.fallback,
  });
}
