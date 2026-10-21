import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk/data/settings/prefs_settings_repository.dart';
import 'package:walk/domain/alarm/entity/alarm_pause.dart';
import 'package:walk/domain/settings/entity/app_settings.dart';
import 'package:walk/domain/walk/entity/step_goal.dart';

void main() {
  test('저장한 적이 없으면 시스템 테마', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = PrefsSettingsRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.load(), const AppSettings());
    expect(repository.load().themeMode, AppThemeMode.system);
  });

  test('저장한 테마를 읽는다', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await PrefsSettingsRepository(
      prefs,
    ).save(const AppSettings(themeMode: AppThemeMode.dark));

    expect(PrefsSettingsRepository(prefs).load().themeMode, AppThemeMode.dark);
  });

  test('모르는 값이면 시스템 테마', () async {
    SharedPreferences.setMockInitialValues({
      PrefsSettingsRepository.themeModeKey: 'sepia',
    });
    final repository = PrefsSettingsRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.load().themeMode, AppThemeMode.system);
  });

  test('문자열이 아닌 값이 저장돼 있어도 시스템 테마', () async {
    SharedPreferences.setMockInitialValues({
      PrefsSettingsRepository.themeModeKey: 2,
    });
    final repository = PrefsSettingsRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.load().themeMode, AppThemeMode.system);
  });

  group('하루 목표', () {
    late PrefsSettingsRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = PrefsSettingsRepository(await SharedPreferences.getInstance());
    });

    test('목표 · 축하일 왕복', () async {
      await repo.save(
        AppSettings(stepGoal: 8000, goalCelebratedOn: DateTime(2026, 10, 3)),
      );
      final s = repo.load();
      expect(s.stepGoal, 8000);
      expect(s.goalCelebratedOn, DateTime(2026, 10, 3));
    });

    test('저장값이 없으면 기본 목표 · 축하일 없음', () {
      expect(repo.load().stepGoal, StepGoal.defaultSteps);
      expect(repo.load().goalCelebratedOn, isNull);
    });

    test('깨진 타입 · 범위 밖은 기본/clamp', () async {
      SharedPreferences.setMockInitialValues({
        PrefsSettingsRepository.stepGoalKey: 'x',
        PrefsSettingsRepository.goalCelebratedOnKey: 42,
      });
      final broken = PrefsSettingsRepository(
        await SharedPreferences.getInstance(),
      );
      expect(broken.load().stepGoal, StepGoal.defaultSteps);
      expect(broken.load().goalCelebratedOn, isNull);

      SharedPreferences.setMockInitialValues({
        PrefsSettingsRepository.stepGoalKey: 99999,
      });
      final big = PrefsSettingsRepository(
        await SharedPreferences.getInstance(),
      );
      expect(big.load().stepGoal, StepGoal.max);
    });

    test('저장이 끝나기 전에 읽어 다시 저장해도 앞선 목표를 잃지 않는다', () async {
      // 목표 변경 저장이 진행 중일 때 축하 판정이 읽고-고쳐-쓴다(걷기 탭 리스너).
      final goalSave = repo.save(const AppSettings(stepGoal: 6000));
      final celebrationSave = repo.save(
        repo.load().copyWith(goalCelebratedOn: DateTime(2026, 10, 3)),
      );
      await Future.wait([goalSave, celebrationSave]);

      final reread = PrefsSettingsRepository(
        await SharedPreferences.getInstance(),
      ).load();
      expect(reread.stepGoal, 6000);
      expect(reread.goalCelebratedOn, DateTime(2026, 10, 3));
    });

    test('축하일 null 저장은 키를 지운다', () async {
      await repo.save(AppSettings(goalCelebratedOn: DateTime(2026, 10, 3)));
      await repo.save(const AppSettings());
      expect(repo.load().goalCelebratedOn, isNull);
    });
  });

  group('공휴일 미리 알림', () {
    late PrefsSettingsRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = PrefsSettingsRepository(await SharedPreferences.getInstance());
    });

    test('저장값이 없으면 켬', () {
      expect(repo.load().holidayReminder, isTrue);
    });

    test('끔 · 켬 왕복', () async {
      await repo.save(const AppSettings(holidayReminder: false));
      expect(repo.load().holidayReminder, isFalse);
      await repo.save(const AppSettings());
      expect(repo.load().holidayReminder, isTrue);
    });

    test('다른 설정을 바꿔도 유지된다', () async {
      await repo.save(const AppSettings(holidayReminder: false));
      await repo.save(repo.load().copyWith(stepGoal: 9000));
      expect(repo.load().holidayReminder, isFalse);
    });

    test('bool 이 아닌 값이면 켬', () async {
      SharedPreferences.setMockInitialValues({
        PrefsSettingsRepository.holidayReminderKey: 'no',
      });
      final broken = PrefsSettingsRepository(
        await SharedPreferences.getInstance(),
      );
      expect(broken.load().holidayReminder, isTrue);
    });
  });

  group('쉬는 기간', () {
    late PrefsSettingsRepository repo;
    final pause = AlarmPause(from: DateTime(2026, 10, 8), until: DateTime(2026, 10, 12));

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = PrefsSettingsRepository(await SharedPreferences.getInstance());
    });

    test('저장값이 없으면 null', () {
      expect(repo.load().pause, isNull);
    });

    test('날짜만 왕복한다', () async {
      await repo.save(AppSettings(pause: pause));
      final reread = PrefsSettingsRepository(await SharedPreferences.getInstance());
      expect(reread.load().pause, pause);
      expect(
        (await SharedPreferences.getInstance()).getString(PrefsSettingsRepository.pauseFromKey),
        '2026-10-08',
      );
    });

    test('null 로 저장하면 지운다', () async {
      await repo.save(AppSettings(pause: pause));
      await repo.save(const AppSettings());
      expect(repo.load().pause, isNull);
    });

    test('다른 설정을 바꿔도 유지된다', () async {
      await repo.save(AppSettings(pause: pause));
      await repo.save(repo.load().copyWith(stepGoal: 9000));
      expect(repo.load().pause, pause);
    });

    test('한쪽만 있거나 날짜가 아니면 null', () async {
      SharedPreferences.setMockInitialValues({
        PrefsSettingsRepository.pauseFromKey: '2026-10-08',
        PrefsSettingsRepository.pauseUntilKey: 7,
      });
      final broken = PrefsSettingsRepository(await SharedPreferences.getInstance());
      expect(broken.load().pause, isNull);
    });
  });
}
