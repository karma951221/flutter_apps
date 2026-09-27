import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:walk/domain/clock.dart';
import 'package:walk/domain/walk/entity/daily_activity.dart';
import 'package:walk/domain/walk/entity/period_kind.dart';
import 'package:walk/domain/walk/repository/activity_repository.dart';
import 'package:walk/domain/walk/usecase/walk_use_case.dart';

class _MockRepository extends Mock implements ActivityRepository {}

class _FixedClock extends Clock {
  _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime now() => _now;
}

void main() {
  late _MockRepository repository;
  late WalkUseCase useCase;

  setUpAll(() => registerFallbackValue(DateTime(2026)));
  setUp(() {
    repository = _MockRepository();
    // 수요일 오후
    useCase = DefaultWalkUseCase(repository, _FixedClock(DateTime(2026, 9, 23, 15)));
  });

  test('today 는 오늘 자정 하루만 읽는다', () async {
    final today = DailyActivity(date: DateTime(2026, 9, 23), steps: 6240);
    when(() => repository.dailyActivities(DateTime(2026, 9, 23), DateTime(2026, 9, 23)))
        .thenAnswer((_) async => Ok([today]));

    final result = await useCase.today();

    expect(result, isA<Ok<DailyActivity>>());
    expect((result as Ok<DailyActivity>).value, today);
  });

  test('이번 주는 오늘까지만 읽고 남은 날은 0보로 채운다', () async {
    when(() => repository.dailyActivities(DateTime(2026, 9, 21), DateTime(2026, 9, 23)))
        .thenAnswer((_) async => Ok([
              for (var d = 21; d <= 23; d++)
                DailyActivity(date: DateTime(2026, 9, d), steps: 100),
            ]));

    final result = await useCase.period(PeriodKind.week, 0);

    final period = (result as Ok).value;
    expect(period.days, hasLength(7));
    expect(period.days.last, DailyActivity.empty(DateTime(2026, 9, 27)));
    expect(period.today, DateTime(2026, 9, 23));
    expect(period.isCurrent, isTrue);
  });

  test('지난 달은 기간 전체를 읽는다', () async {
    when(() => repository.dailyActivities(DateTime(2026, 8, 1), DateTime(2026, 8, 31)))
        .thenAnswer((_) async => Ok([
              for (var d = 1; d <= 31; d++) DailyActivity.empty(DateTime(2026, 8, d)),
            ]));

    final result = await useCase.period(PeriodKind.month, -1);

    expect((result as Ok).value.days, hasLength(31));
  });

  test('읽기 실패는 그대로 전파한다', () async {
    when(() => repository.dailyActivities(any(), any()))
        .thenAnswer((_) async => const Err(Failure.unknown()));

    expect(await useCase.today(), isA<Err<DailyActivity>>());
    expect(await useCase.period(PeriodKind.week, 0), isA<Err>());
  });
}
