import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/lock/device_auth.dart';
import '../../../domain/lock/lock_config.dart';
import '../../../domain/lock/lock_repository.dart';
import '../cubit/lock_setup_cubit.dart';
import '../cubit/lock_setup_state.dart';
import '../widget/lock_secret_input.dart';

/// 일기 잠금 켜기 · 끄기 · 방식 변경(스펙 §7 · §8). 설정 탭이 push 한다.
/// 마치면 알리고 `true` 로 닫힌다. 뒤로 가면 결과는 null.
class LockSetupPage extends StatefulWidget {
  const LockSetupPage({super.key});

  @override
  State<LockSetupPage> createState() => _LockSetupPageState();
}

class _LockSetupPageState extends State<LockSetupPage> {
  late final _cubit = LockSetupCubit(
    getIt<LockRepository>(),
    getIt<DeviceAuth>(),
    getIt<Clock>(),
  )..start();

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkLockSetupTitle)),
      body: BlocListener<LockSetupCubit, LockSetupState>(
        bloc: _cubit,
        listenWhen: (_, next) => next is SetupDone,
        listener: (context, _) {
          AppSnackBar.show(
            context,
            message: l10n.walkLockSetupSaved,
            type: AppSnackBarType.success,
          );
          Navigator.of(context).pop(true);
        },
        child: LockSetupView(cubit: _cubit),
      ),
    );
  }
}

/// [LockSetupCubit] 상태를 그린다. 설정 화면과 잠금 게이트의 재설정이 함께 쓴다.
class LockSetupView extends StatefulWidget {
  const LockSetupView({required this.cubit, super.key});

  final LockSetupCubit cubit;

  @override
  State<LockSetupView> createState() => _LockSetupViewState();
}

class _LockSetupViewState extends State<LockSetupView> {
  /// 현재 비밀 확인이 막힌 동안 남은 시간을 줄인다.
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => widget.cubit.tick(),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = widget.cubit;
    return BlocBuilder<LockSetupCubit, LockSetupState>(
      bloc: cubit,
      builder: (context, state) => switch (state) {
        SetupLoading() ||
        SetupDone() => const Center(child: CircularProgressIndicator()),
        SetupNeedsScreenLock() => AppPlaceholder(
          icon: Icons.lock_outline,
          message: l10n.walkLockNeedsScreenLock,
        ),
        SetupVerifying(
          :final method,
          :final blockedFor,
          :final longBlock,
          :final wrong,
        ) =>
          LockPromptLayout(
            prompt: l10n.walkLockSetupVerify,
            status:
                lockBlockedMessage(l10n, blockedFor, longBlock: longBlock) ??
                (wrong ? l10n.walkLockWrong : null),
            input: LockSecretInput(
              method: method,
              enabled: blockedFor == null,
              error: wrong,
              onSecret: cubit.verifyCurrent,
            ),
          ),
        SetupChoosing(:final current, :final canTurnOff) => LockPromptLayout(
          prompt: l10n.walkLockSetupChoose,
          input: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final method in LockMethod.values) ...[
                AppButton.secondary(
                  label: method == current
                      ? l10n.walkLockSetupInUse(_methodLabel(l10n, method))
                      : _methodLabel(l10n, method),
                  onPressed: () => cubit.choose(method),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
          footer: canTurnOff
              ? AppButton.text(
                  label: l10n.walkLockSetupOff,
                  onPressed: cubit.turnOff,
                )
              : null,
        ),
        SetupEntering(:final method, :final confirming, :final error) =>
          LockPromptLayout(
            prompt: confirming
                ? l10n.walkLockSetupConfirm
                : switch (method) {
                    LockMethod.pin => l10n.walkLockSetupNewPin,
                    LockMethod.pattern => l10n.walkLockSetupNewPattern,
                  },
            status: switch (error) {
              LockSetupError.mismatch => l10n.walkLockSetupMismatch,
              LockSetupError.tooShort => l10n.walkLockSetupTooShort,
              null => null,
            },
            input: LockSecretInput(
              // 첫 입력 ↔ 확인 입력이 바뀌면 입력 중이던 것을 비운다.
              key: ValueKey((method, confirming)),
              method: method,
              error: error != null,
              onSecret: cubit.enter,
            ),
          ),
      },
    );
  }
}

String _methodLabel(AppLocalizations l10n, LockMethod method) =>
    switch (method) {
      LockMethod.pin => l10n.walkLockSetupPin,
      LockMethod.pattern => l10n.walkLockSetupPattern,
    };
