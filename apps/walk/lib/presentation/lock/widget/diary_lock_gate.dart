import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/lock/device_auth.dart';
import '../../../domain/lock/lock_config.dart';
import '../../../domain/lock/lock_repository.dart';
import '../cubit/diary_lock_cubit.dart';
import '../cubit/diary_lock_state.dart';
import '../cubit/lock_setup_cubit.dart';
import '../page/lock_setup_page.dart';
import 'lock_secret_input.dart';

/// 일기 잠금 게이트(스펙 §7). 위에서 [DiaryLockCubit] 를 받는다(셸이 소유 · start).
///
/// [child] 는 잠금이 풀렸을 때만 build 한다 — 잠긴 동안 기록 위젯은 트리에 아예 없다
/// (덮어 가리는 것이 아니다).
///
/// "잠긴 동안 기록 내용을 보이지 않는다"의 주인이기도 하다: 다시 잠기는 순간 내비게이터 맨 위의
/// 팝업(바텀 시트 · 다이얼로그 · 메뉴)을 모두 닫는다. 팝업은 게이트 위의 별도 경로라 게이트가
/// 화면을 바꿔도 남기 때문이다. 화면(페이지) 경로는 닫지 않는다 — 그 화면의 게이트가 가린다.
/// [dismissPopups] 가 false 면(셸에서 가려진 탭) 닫지 않는다 — 그 팝업은 다른 탭의 것이다.
class DiaryLockGate extends StatelessWidget {
  const DiaryLockGate({
    required this.child,
    this.dismissPopups = true,
    super.key,
  });

  final Widget child;
  final bool dismissPopups;

  @override
  Widget build(BuildContext context) =>
      BlocListener<DiaryLockCubit, DiaryLockState>(
        listenWhen: (a, b) => a is! LockLocked && b is LockLocked,
        listener: (context, _) {
          if (!dismissPopups) return;
          Navigator.of(context).popUntil((route) => route is! PopupRoute);
        },
        child: BlocBuilder<DiaryLockCubit, DiaryLockState>(
          builder: (context, state) => switch (state) {
            LockUnlocked() => child,
            LockLocked() => _LockScreen(state: state),
            LockResetting() => const _ResetScreen(),
          },
        ),
      );
}

/// 잠금 해제 입력. 차단 중이면 1초마다 남은 시간을 갱신한다.
class _LockScreen extends StatefulWidget {
  const _LockScreen({required this.state});

  final LockLocked state;

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => context.read<DiaryLockCubit>().tick(),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<DiaryLockCubit>();
    final state = widget.state;
    final blocked = state.blockedFor != null;
    return LockPromptLayout(
      title: l10n.walkLockTitle,
      prompt: switch (state.method) {
        LockMethod.pin => l10n.walkLockEnterPin,
        LockMethod.pattern => l10n.walkLockEnterPattern,
      },
      status:
          lockBlockedMessage(
            l10n,
            state.blockedFor,
            longBlock: state.longBlock,
          ) ??
          (state.wrong ? l10n.walkLockWrong : null) ??
          (state.deviceUnavailable ? l10n.walkLockDeviceUnavailable : null),
      input: LockSecretInput(
        method: state.method,
        enabled: !blocked,
        error: state.wrong,
        onSecret: cubit.submit,
      ),
      footer: AppButton.text(
        label: l10n.walkLockForgot,
        onPressed: blocked
            ? null
            : () => cubit.forgot(l10n.walkLockDeviceReason),
      ),
    );
  }
}

/// 폰 인증을 통과한 뒤 새 PIN · 패턴 등록. 마치면 [DiaryLockCubit.finishReset] 이 잠금을 푼다.
class _ResetScreen extends StatefulWidget {
  const _ResetScreen();

  @override
  State<_ResetScreen> createState() => _ResetScreenState();
}

class _ResetScreenState extends State<_ResetScreen> {
  late final _setup = LockSetupCubit(
    getIt<LockRepository>(),
    getIt<DeviceAuth>(),
    getIt<Clock>(),
  )..startReset(context.read<DiaryLockCubit>().finishReset);

  @override
  void dispose() {
    _setup.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LockSetupView(cubit: _setup);
}
