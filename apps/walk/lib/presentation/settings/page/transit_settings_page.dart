import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/transit/repository/transit_key_store.dart';
import '../../../domain/transit/usecase/verify_transit_key.dart';
import '../../transit/cubit/transit_key_cubit.dart';
import '../../transit/cubit/transit_key_state.dart';

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

  /// 마지막으로 본 입력 — 선택 · 커서 이동만으로는 거절 문구를 지우지 않는다.
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
    context.read<TransitKeyCubit>().clearRejection();
    setState(() {});
  }

  String get _key => _controller.text.trim();

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<TransitKeyCubit>();
    var result = await cubit.save(_key);
    if (!mounted) return;
    if (result == TransitKeySave.network) {
      final ok = await AppConfirmDialog.show(
        context,
        title: l10n.walkTransitKeyUnverifiedTitle,
        content: l10n.walkTransitKeyUnverifiedBody,
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
        // 서버 원문은 입력칸 아래에 이미 보인다.
        break;
      case TransitKeySave.network:
      case TransitKeySave.failed:
        AppSnackBar.error(context, message: l10n.walkTransitKeySaveFailed);
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
                  errorText: state.rejectedMessage,
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
