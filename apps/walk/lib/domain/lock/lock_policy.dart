import 'lock_attempts.dart';

/// 잠금 해제 실패 · 차단 규칙(스펙 §7). 경과 시간은 `Duration` 으로 비교한다.
abstract final class LockPolicy {
  static const maxFailures = 5;
  static const shortBlock = Duration(seconds: 30);
  static const longBlock = Duration(hours: 24);

  /// PIN · 패턴을 틀렸다. [maxFailures] 번째면 [shortBlock] 차단하고 횟수를 0 으로.
  static LockAttempts wrongSecret(LockAttempts a, DateTime now) {
    final failures = a.failures + 1;
    if (failures < maxFailures) return LockAttempts(failures: failures);
    return LockAttempts(blockedUntil: now.add(shortBlock));
  }

  /// 폰 인증에 실패했다(취소는 실패가 아니다 — 부르지 않는다). [longBlock] 동안 모두 거절.
  static LockAttempts deviceAuthFailed(DateTime now) =>
      LockAttempts(blockedUntil: now.add(longBlock), longBlock: true);

  /// 해제 성공 · 재설정 완료.
  static LockAttempts success() => const LockAttempts();

  /// 차단 중이면 남은 시간. now < blockedUntil 만 차단. 시계가 blockedUntil-기간 보다
  /// 앞으로 거꾸로 가면 남은 시간을 전체 기간으로 본다(보수적).
  static Duration? remaining(LockAttempts a, DateTime now) {
    final until = a.blockedUntil;
    if (until == null || !now.isBefore(until)) return null;
    final period = a.longBlock ? longBlock : shortBlock;
    final left = until.difference(now);
    return left > period ? period : left;
  }
}

/// 패턴 입력 규칙. 점은 3×3 격자의 인덱스(0~8, 왼쪽 위부터 가로로)이고,
/// 비밀 문자열은 점 인덱스를 '-' 로 이은 것('0-1-2-5')이다.
abstract final class PatternRule {
  static const minDots = 4;

  /// 드래그로 지난 점 목록에 건너뛴 가운데 점을 끼워 넣는다(이미 쓴 점이면 넣지 않음). 0→2 이면 1 포함.
  static List<int> withSkipped(List<int> dots) {
    final result = <int>[];
    for (final dot in dots) {
      if (result.isNotEmpty) {
        final middle = _middle(result.last, dot);
        if (middle != null && !result.contains(middle)) result.add(middle);
      }
      result.add(dot);
    }
    return result;
  }

  /// 두 점 사이 정확히 가운데 있는 격자 점. 없으면 null.
  static int? _middle(int from, int to) {
    final rowSum = from ~/ 3 + to ~/ 3;
    final colSum = from % 3 + to % 3;
    if (rowSum.isOdd || colSum.isOdd) return null;
    final middle = (rowSum ~/ 2) * 3 + colSum ~/ 2;
    return middle == from || middle == to ? null : middle;
  }
}
