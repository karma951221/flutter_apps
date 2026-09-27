import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../domain/entity/health_access.dart';
import '../../domain/entity/period_kind.dart';
import '../../domain/usecase/walk_use_case.dart';
import '../cubit/health_access_cubit.dart';
import '../cubit/health_access_state.dart';
import '../cubit/period_activity_cubit.dart';
import '../cubit/today_activity_cubit.dart';
import '../cubit/today_activity_state.dart';
import '../widget/period_section.dart';
import '../widget/today_activity_card.dart';

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
    await _access.check();
    if (_access.state.access == HealthAccess.granted) await _refresh();
  }

  void _load() {
    _today.load();
    _week.load();
    _month.load();
  }

  Future<void> _refresh() =>
      Future.wait([_today.refresh(), _week.refresh(), _month.refresh()]);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkAppTitle)),
      body: BlocConsumer<HealthAccessCubit, HealthAccessState>(
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
    );
  }

  Widget _dashboard(AppLocalizations l10n) => RefreshIndicator(
    onRefresh: _refresh,
    child: ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        BlocBuilder<TodayActivityCubit, TodayActivityState>(
          bloc: _today,
          builder: (context, state) => switch (state) {
            TodayActivityLoading() => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            TodayActivityFailure() => AppPlaceholder(
              message: l10n.walkLoadFailed,
              actionLabel: l10n.commonRetry,
              onAction: _today.load,
            ),
            TodayActivityLoaded(:final activity) => TodayActivityCard(
              activity: activity,
            ),
          },
        ),
        const SizedBox(height: AppSpacing.md),
        // ListView 가 화면 밖 탭바를 버렸다 다시 만들어도 선택이 [_kind] 와 어긋나지 않게.
        DefaultTabController(
          length: PeriodKind.values.length,
          initialIndex: _kind.index,
          child: TabBar(
            onTap: (index) => setState(() => _kind = PeriodKind.values[index]),
            tabs: [
              Tab(text: l10n.walkTabWeek),
              Tab(text: l10n.walkTabMonth),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        PeriodSection(
          key: ValueKey(_kind),
          cubit: switch (_kind) {
            PeriodKind.week => _week,
            PeriodKind.month => _month,
          },
        ),
      ],
    ),
  );
}
