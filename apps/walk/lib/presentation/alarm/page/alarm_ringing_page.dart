import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/usecase/alarm_use_case.dart';
import '../cubit/alarm_ringing_cubit.dart';
import '../cubit/alarm_ringing_state.dart';
import '../format/alarm_format.dart';
import '../widget/ringing_ripple.dart';

/// 앱이 살아 있을 때 울리는 알람 화면(`AlarmRingListener` 가 띄운다). 뒤로가기로는
/// 닫히지 않는다 — 끄거나 미뤄야 닫힌다. 잠금 화면 위에서도 읽히게 가운데에 크게 둔다.
class AlarmRingingPage extends StatefulWidget {
  const AlarmRingingPage({required this.packageId, super.key});

  final int packageId;

  @override
  State<AlarmRingingPage> createState() => _AlarmRingingPageState();
}

class _AlarmRingingPageState extends State<AlarmRingingPage> {
  late final _cubit = AlarmRingingCubit(getIt<AlarmUseCase>(), widget.packageId)..load();
  final _clock = getIt<Clock>();
  late DateTime _now = _clock.now();
  Timer? _ticker;

  /// 잠금 화면에서 장갑 낀 손으로도 누르기 쉬운 버튼 높이. 문구(`5분 뒤 다시 울림`)가
  /// 반 폭에 들어가게 가로 여백을 줄이고, 두 줄이 되어도 위아래 여백을 둔다.
  static const _buttonStyle = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size.fromHeight(AppSpacing.xl * 1.75)),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
    ),
  );

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = _clock.now();
      if (now.minute != _now.minute || now.hour != _now.hour) setState(() => _now = now);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _cubit.close();
    super.dispose();
  }

  Future<void> _finish(Future<void> Function() action) async {
    await action();
    if (!mounted) return;
    // 알림 쪽에서 먼저 꺼져 리스너가 이미 이 화면을 걷었을 수 있다.
    final route = ModalRoute.of(context);
    if (route == null) return;
    if (route.isCurrent) {
      Navigator.of(context).pop();
    } else if (route.isActive) {
      Navigator.of(context).removeRoute(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.primaryContainer,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: BlocBuilder<AlarmRingingCubit, AlarmRingingState>(
              bloc: _cubit,
              builder: (context, state) {
                final label = state.alarm?.label ?? '';
                return Column(
                  children: [
                    const Spacer(),
                    RingingRipple(
                      child: Icon(
                        Icons.alarm,
                        size: AppSpacing.xl * 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FittedBox(
                      child: Text(
                        AlarmFormat.time(context, _now.hour, _now.minute),
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      label.isEmpty ? l10n.walkAlarmDefaultTitle : label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const Spacer(),
                    // 문구가 길어 좁은 폭에서는 두 줄이 된다. 두 버튼 높이를 맞춘다.
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: AppButton.secondary(
                              label: l10n.walkAlarmSnooze,
                              style: _buttonStyle,
                              onPressed: state.busy ? null : () => _finish(_cubit.snooze),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppButton.primary(
                              label: l10n.walkAlarmStop,
                              style: _buttonStyle,
                              onPressed: state.busy ? null : () => _finish(_cubit.stop),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
