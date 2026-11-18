import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/transit/repository/transit_key_store.dart';
import '../../../domain/transit/transit_failure.dart';
import '../../../domain/transit/usecase/verify_transit_key.dart';
import '../../transit/cubit/transit_key_cubit.dart';
import '../../transit/cubit/transit_key_state.dart';
import '../../transit/widget/transit_failure_cause.dart';

/// 길찾기 설정 — ODsay 키 입력 · 확인 상태 · 삭제 · 발급 안내. 잠금 밖 화면이다.
class TransitSettingsPage extends StatelessWidget {
  const TransitSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) =>
          TransitKeyCubit(getIt<TransitKeyStore>(), getIt<VerifyTransitKey>())
            ..load(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.walkTransitSettingsTitle)),
        body: const _TransitKeyView(),
      ),
    );
  }
}

class _TransitKeyView extends StatefulWidget {
  const _TransitKeyView();

  @override
  State<_TransitKeyView> createState() => _TransitKeyViewState();
}

class _TransitKeyViewState extends State<_TransitKeyView> {
  final _controller = TextEditingController();
  bool _obscure = true;

  /// 마지막으로 본 입력 — 선택 · 커서 이동만으로는 실패 안내를 지우지 않는다.
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_controller.text == _lastText) return;
    _lastText = _controller.text;
    context.read<TransitKeyCubit>().clearFailure();
    setState(() {});
  }

  String get _key => _controller.text.trim();

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<TransitKeyCubit>();
    var result = await cubit.save(_key);
    if (!mounted) return;
    if (result == TransitKeySave.network) {
      final cause = cubit.state.failure?.detail ?? '';
      final ok = await AppConfirmDialog.show(
        context,
        title: l10n.walkTransitKeyUnverifiedTitle,
        content: cause.isEmpty
            ? l10n.walkTransitKeyUnverifiedBody
            : l10n.walkTransitKeyUnverifiedBodyWithCause(cause),
        confirmLabel: l10n.walkTransitKeyUnverifiedConfirm,
        isDestructive: false,
      );
      if (!ok || !mounted) return;
      result = await cubit.save(_key, saveIfUnverified: true);
      if (!mounted) return;
    }
    switch (result) {
      case TransitKeySave.connected:
        _controller.clear();
        AppSnackBar.success(context, message: l10n.walkTransitKeySaved);
      case TransitKeySave.unverified:
        _controller.clear();
        AppSnackBar.info(context, message: l10n.walkTransitKeySavedUnverified);
      case TransitKeySave.rejected:
      case TransitKeySave.network:
      case TransitKeySave.failed:
        // 요약과 원인 원문은 입력칸 아래 실패 영역에 보인다.
        break;
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<TransitKeyCubit>();
    final ok = await AppConfirmDialog.show(
      context,
      title: l10n.walkTransitKeyDeleteTitle,
      content: l10n.walkTransitKeyDeleteBody,
      confirmLabel: l10n.walkTransitKeyDelete,
    );
    if (!ok) return;
    final done = await cubit.delete();
    if (!mounted) return;
    done
        ? AppSnackBar.success(context, message: l10n.walkTransitKeyDeleted)
        : AppSnackBar.error(context, message: l10n.walkTransitKeyDeleteFailed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return BlocBuilder<TransitKeyCubit, TransitKeyState>(
      builder: (context, state) {
        final status = state.status;
        final (statusLabel, statusColor) = switch (status) {
          TransitKeyStatus.connected => (
            l10n.walkTransitKeyStatusConnected,
            scheme.primary,
          ),
          TransitKeyStatus.unverified => (
            l10n.walkTransitKeyStatusUnverified,
            scheme.onSurfaceVariant,
          ),
          TransitKeyStatus.rejected => (
            l10n.walkChatKeyStatusInvalid,
            scheme.error,
          ),
          null => (null, scheme.onSurfaceVariant),
        };
        return ListView(
          children: [
            AppListTile(
              key: const Key('transit-key-row'),
              leading: const Icon(Icons.key_outlined),
              title: Text(l10n.walkTransitKeyTitle),
              subtitle: state.loading
                  ? null
                  : Text(state.keyPreview ?? l10n.walkTransitKeyEmpty),
              trailing: statusLabel == null
                  ? null
                  : Text(
                      statusLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: statusColor,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: TextField(
                key: const Key('transit-key-input'),
                controller: _controller,
                enabled: !state.busy,
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: l10n.walkTransitKeyInputHint,
                  suffixIcon: IconButton(
                    key: const Key('transit-key-visibility'),
                    tooltip: _obscure
                        ? l10n.walkChatKeyShow
                        : l10n.walkChatKeyHide,
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
            ),
            if (state.failure case final failure?)
              _KeyFailure(failure: failure),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: AppButton.primary(
                key: const Key('transit-key-save'),
                label: l10n.walkTransitKeySave,
                isLoading: state.busy,
                onPressed: state.busy || _key.isEmpty
                    ? null
                    : () => unawaited(_save()),
              ),
            ),
            if (state.keyPreview != null)
              AppListTile(
                key: const Key('transit-key-delete'),
                leading: const Icon(Icons.link_off_outlined),
                title: Text(l10n.walkTransitKeyDelete),
                onTap: state.busy ? null : _delete,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Text(
                l10n.walkTransitKeyGuide,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 키 저장 실패 영역 — 요약 · (거절이면) 콘솔 확인 안내 · 원인 원문.
class _KeyFailure extends StatelessWidget {
  const _KeyFailure({required this.failure});

  final TransitFailure failure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (String summary, String? hint) = switch (failure) {
      TransitKeyRejected() => (
        l10n.walkTransitKeyRejected,
        l10n.walkTransitKeyRejectedHint,
      ),
      TransitNetwork() => (l10n.walkTransitKeyNetworkFailed, null),
      TransitQuotaExceeded() => (
        l10n.walkTransitQuota,
        l10n.walkTransitQuotaBody,
      ),
      TransitMissingKey() ||
      TransitNoRoute() ||
      TransitTooClose() ||
      TransitServer() ||
      TransitUnexpected() => (l10n.walkTransitKeySaveFailed, null),
    };
    final detail = failure.detail;
    return Padding(
      key: const Key('transit-key-failure'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary,
            style: theme.textTheme.titleSmall?.copyWith(color: scheme.error),
          ),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (detail.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            TransitFailureCause(detail),
          ],
        ],
      ),
    );
  }
}
