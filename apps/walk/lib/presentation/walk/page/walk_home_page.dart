import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/settings/repository/settings_repository.dart';
import '../../../domain/walk/entity/daily_activity.dart';
import '../../../domain/walk/entity/goal_progress.dart';
import '../../../domain/walk/entity/health_access.dart';
import '../../../domain/walk/entity/period_kind.dart';
import '../../../domain/walk/usecase/walk_use_case.dart';
import '../cubit/health_access_cubit.dart';
import '../cubit/health_access_state.dart';
import '../../theme/walk_motion.dart';
import '../cubit/period_activity_cubit.dart';
import '../cubit/step_goal_cubit.dart';
import '../cubit/today_activity_cubit.dart';
import '../cubit/today_activity_state.dart';
import '../widget/period_section.dart';
import '../widget/today_goal_card.dart';
import '../widget/walk_skeleton.dart';

/// 한 화면짜리 앱의 홈. 시작할 때 접근을 확인하고(권한이 없으면 이번 세션에 한 번
/// 요청 화면이 뜬다), 접근 상태가 granted 가 되는 순간 세 cubit 을 읽고,
/// 백그라운드에서 돌아올 때마다 접근을 다시 확인한 뒤 새로 읽는다
/// (자정을 넘겨 돌아오면 use case 가 새 "오늘"로 계산한다).
class WalkHomePage extends StatefulWidget {
  const WalkHomePage({super.key});

  @override
  State<WalkHomePage> createState() => _WalkHomePageState();
}

class _WalkHomePageState extends State<WalkHomePage> {
  final _useCase = getIt<WalkUseCase>();
  late final _access = HealthAccessCubit(_useCase)..check();
  late final _today = TodayActivityCubit(_useCase);
  late final _week = PeriodActivityCubit(_useCase, PeriodKind.week);
  late final _month = PeriodActivityCubit(_useCase, PeriodKind.month);
  late final AppLifecycleListener _lifecycle;
  PeriodKind _kind = PeriodKind.week;

  /// 이 화면이 떠 있는 동안 오늘 목표 달성을 처음 본 순간 참이 된다(카드가 한 번 연출한다).
  bool _celebrate = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _access.close();
    _today.close();
    _week.close();
    _month.close();
    super.dispose();
  }

  Future<void> _onResume() async {
    // 복귀 확인으로 막 granted 가 됐으면 리스너가 이미 _load() 한다 — 두 번 읽지 않는다.
    final wasGranted = _access.state.access == HealthAccess.granted;
    await _access.check();
    if (wasGranted && _access.state.access == HealthAccess.granted) {
      await _refresh();
    }
  }

  void _load() {
    _today.load();
    _week.load();
    _month.load();
  }

  Future<void> _refresh() =>
      Future.wait([_today.refresh(), _week.refresh(), _month.refresh()]);

  /// 오늘 값이나 목표가 바뀔 때마다 본다. 오늘 아직 축하하지 않았으면 연출을 켜고
  /// 같은 프레임에 오늘 날짜를 저장해, 같은 날 다시 열면 연출하지 않는다.
  void _judgeCelebration(DailyActivity activity, int goal) {
    final settings = getIt<SettingsRepository>();
    final saved = settings.load();
    final today = DateUtils.dateOnly(activity.date);
    if (!shouldCelebrate(
      steps: activity.steps,
      goal: goal,
      today: today,
      lastCelebratedOn: saved.goalCelebratedOn,
    )) {
      return;
    }
    setState(() => _celebrate = true);
    unawaited(settings.save(saved.copyWith(goalCelebratedOn: today)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkShellTabWalk)),
      // 오늘 값은 대시보드가 그려지기 전에 도착할 수 있어 화면 맨 위에서 듣는다.
      body: BlocListener<TodayActivityCubit, TodayActivityState>(
        bloc: _today,
        listener: (context, state) {
          if (state case TodayActivityLoaded(:final activity)) {
            _judgeCelebration(activity, context.read<StepGoalCubit>().state);
          }
        },
        child: BlocConsumer<HealthAccessCubit, HealthAccessState>(
          bloc: _access,
          listenWhen: (previous, current) =>
              previous.access != HealthAccess.granted &&
              current.access == HealthAccess.granted,
          listener: (_, _) => _load(),
          builder: (context, state) => switch (state.access) {
            null => const Center(child: CircularProgressIndicator()),
            HealthAccess.notInstalled => Center(
              child: AppPlaceholder(
                icon: Icons.health_and_safety_outlined,
                message: l10n.walkHealthConnectMissing,
                description: l10n.walkHealthConnectMissingDescription,
                actionLabel: l10n.walkInstall,
                onAction: _access.openInstall,
              ),
            ),
            HealthAccess.updateRequired => Center(
              child: AppPlaceholder(
                icon: Icons.system_update_outlined,
                message: l10n.walkHealthConnectUpdate,
                actionLabel: l10n.walkUpdate,
                onAction: _access.openInstall,
              ),
            ),
            HealthAccess.permissionDenied => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppPlaceholder(
                    icon: Icons.directions_walk,
                    message: l10n.walkPermissionNeeded,
                    description: l10n.walkPermissionDescription,
                    actionLabel: l10n.walkGrantPermission,
                    onAction: _access.request,
                  ),
                  // Health Connect 는 두 번 거부하면 다이얼로그를 생략한다 — 그때의 출구.
                  if (state.canOpenSettings)
                    AppButton.text(
                      label: l10n.walkOpenSettings,
                      onPressed: _access.openSettings,
                    ),
                ],
              ),
            ),
            HealthAccess.granted => _dashboard(l10n),
          },
        ),
      ),
    );
  }

  Widget _dashboard(AppLocalizations l10n) => BlocListener<StepGoalCubit, int>(
    // 목표를 낮춰 새로 달성해도 축하한다. 목록 바깥에 두어 카드가 화면 밖이어도 듣는다.
    listener: (context, goal) {
      if (_today.state case TodayActivityLoaded(:final activity)) {
        _judgeCelebration(activity, goal);
      }
    },
    child: RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          BlocBuilder<TodayActivityCubit, TodayActivityState>(
            bloc: _today,
            builder: (context, state) => switch (state) {
              TodayActivityLoading() => const WalkSkeleton(
                height: AppSpacing.xl * 9,
              ),
              TodayActivityFailure() => AppPlaceholder(
                message: l10n.walkLoadFailed,
                actionLabel: l10n.commonRetry,
                onAction: _today.load,
              ),
              TodayActivityLoaded(:final activity) => TodayGoalCard(
                activity: activity,
                goal: context.select((StepGoalCubit c) => c.state),
                celebrate: _celebrate,
              ),
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: SegmentedButton<PeriodKind>(
              segments: [
                ButtonSegment(
                  value: PeriodKind.week,
                  label: Text(l10n.walkTabWeek),
                ),
                ButtonSegment(
                  value: PeriodKind.month,
                  label: Text(l10n.walkTabMonth),
                ),
              ],
              selected: {_kind},
              showSelectedIcon: false,
              onSelectionChanged: (selected) =>
                  setState(() => _kind = selected.first),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedSwitcher(
            duration: WalkMotion.off(context)
                ? Duration.zero
                : WalkMotion.medium,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: PeriodSection(
              key: ValueKey(_kind),
              cubit: switch (_kind) {
                PeriodKind.week => _week,
                PeriodKind.month => _month,
              },
            ),
          ),
        ],
      ),
    ),
  );
}
