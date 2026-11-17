import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

import '../entity/activity_period.dart';
import '../entity/daily_activity.dart';
import '../entity/health_access.dart';
import '../entity/period_kind.dart';
import '../entity/period_range.dart';
import '../repository/activity_repository.dart';

abstract interface class WalkUseCase {
  Future<HealthAccess> access();

  Future<HealthAccess> requestAccess();

  bool get permissionDeclinedThisSession;

  Future<void> openPermissionSettings();

  Future<void> openInstall();

  Future<Result<DailyActivity>> today();

  /// [offset] 0 = 현재 기간, -1 = 그 전 기간.
  Future<Result<ActivityPeriod>> period(PeriodKind kind, int offset);
}

@LazySingleton(as: WalkUseCase)
class DefaultWalkUseCase implements WalkUseCase {
  DefaultWalkUseCase(this._repository, this._clock);

  final ActivityRepository _repository;
  final Clock _clock;

  @override
  Future<HealthAccess> access() => _repository.access();

  @override
  Future<HealthAccess> requestAccess() => _repository.requestAccess();

  @override
  bool get permissionDeclinedThisSession =>
      _repository.permissionDeclinedThisSession;

  @override
  Future<void> openPermissionSettings() => _repository.openPermissionSettings();

  @override
  Future<void> openInstall() => _repository.openInstall();

  @override
  Future<Result<DailyActivity>> today() async {
    final today = dateOnly(_clock.now());
    final result = await _repository.dailyActivities(today, today);
    return switch (result) {
      Ok(value: final days) => Ok(days.isEmpty ? DailyActivity.empty(today) : days.first),
      Err(:final failure) => Err(failure),
    };
  }

  @override
  Future<Result<ActivityPeriod>> period(PeriodKind kind, int offset) async {
    final today = dateOnly(_clock.now());
    final range = periodRange(kind, offset, today);
    final readUntil = range.end.isAfter(today) ? today : range.end;
    final result = await _repository.dailyActivities(range.start, readUntil);
    return switch (result) {
      Ok(value: final read) => Ok(
        ActivityPeriod(
          kind: kind,
          start: range.start,
          end: range.end,
          today: today,
          days: [
            ...read,
            for (final day in daysBetween(range.start, range.end))
              if (day.isAfter(readUntil)) DailyActivity.empty(day),
          ],
        ),
      ),
      Err(:final failure) => Err(failure),
    };
  }
}
