import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/chat_connection.dart';
import '../../../domain/chat/chat_settings.dart';
import '../../../domain/chat/chat_vendor.dart';
import '../../../domain/chat/usecase/chat_key_verifier.dart';
import '../../../domain/chat/usecase/chat_model_choice.dart';
import '../../chat/widget/chat_vendor_icon.dart';
import '../../chat/widget/model_chip.dart';
import '../../chat/widget/model_picker_sheet.dart';
import '../cubit/chat_settings_cubit.dart';
import '../cubit/chat_settings_state.dart';
import 'chat_key_dialog.dart';
import 'row_highlight.dart';
import 'vendor_picker_sheet.dart';

/// 물어보기 설정의 섹션 — AI 연결 행(스펙 §6.1)과 데이터 전송 안내.
///
/// 섹션 머리글은 두지 않는다 — 화면 제목(물어보기 설정)과 연결 행 제목(AI 연결)이
/// 이미 같은 말을 한다.
class ChatSettingsSection extends StatelessWidget {
  const ChatSettingsSection({this.highlightConnection = false, super.key});

  /// true 면 화면이 열린 뒤 연결 행을 두 번 glow(§3.2).
  final bool highlightConnection;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatSettingsCubit(
        getIt<ChatSettings>(),
        getIt<ChatKeyVerifier>(),
        getIt<ChatModelChoice>(),
      )..load(),
      child: _ChatSettingsView(highlightConnection: highlightConnection),
    );
  }
}

class _ChatSettingsView extends StatefulWidget {
  const _ChatSettingsView({required this.highlightConnection});

  final bool highlightConnection;

  @override
  State<_ChatSettingsView> createState() => _ChatSettingsViewState();
}

class _ChatSettingsViewState extends State<_ChatSettingsView> {
  /// 등록에 성공할 때마다 올려 연결 행 glow 를 한 번 더 재생한다.
  int _replay = 0;

  /// 미연결 [연결하기] → 벤더 시트 → 키 대화상자.
  Future<void> _connect() async {
    final vendor = await VendorPickerSheet.show(context);
    if (vendor == null || !mounted) return;
    await _openKeyDialog(vendor);
  }

  /// [다른 AI 로 바꾸기] → 벤더 시트(지금 벤더는 체크) → 키 대화상자(바꾸기 확인).
  Future<void> _switchVendor(ChatVendor current) async {
    final vendor = await VendorPickerSheet.show(context, current: current);
    if (vendor == null || vendor == current || !mounted) return;
    await _openKeyDialog(vendor, switchingFrom: current);
  }

  Future<void> _openKeyDialog(
    ChatVendor vendor, {
    ChatVendor? switchingFrom,
  }) async {
    final l10n = AppLocalizations.of(context);
    final result = await ChatKeyDialog.show(
      context,
      vendor: vendor,
      switchingFrom: switchingFrom,
    );
    if (result == null || !mounted) return;
    final name = chatVendorName(l10n, vendor);
    switch (result) {
      case ChatKeyDialogResult.connected:
        AppSnackBar.show(
          context,
          message: l10n.walkChatConnected(name),
          type: AppSnackBarType.success,
        );
      case ChatKeyDialogResult.switched:
        AppSnackBar.show(
          context,
          message: l10n.walkChatSwitchedVendor(name),
          type: AppSnackBarType.success,
        );
      case ChatKeyDialogResult.savedUnverified:
        AppSnackBar.show(context, message: l10n.walkChatSavedUnverified);
    }
    setState(() => _replay++);
  }

  Future<void> _disconnect() async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ChatSettingsCubit>();
    final ok = await AppConfirmDialog.show(
      context,
      title: l10n.walkChatSettingsDeleteTitle,
      content: l10n.walkChatSettingsDeleteBody,
      confirmLabel: l10n.walkChatSettingsDelete,
    );
    if (!ok) return;
    final done = await cubit.disconnect();
    if (!mounted) return;
    AppSnackBar.show(
      context,
      message: done
          ? l10n.walkChatDisconnected
          : l10n.walkChatSettingsDisconnectFailed,
      type: done ? AppSnackBarType.info : AppSnackBarType.error,
    );
  }

  /// 모델 행 → 물어보기 탭 칩과 같은 시트. 바뀐 게 있으면 행을 다시 읽는다.
  Future<void> _pickModel() async {
    final cubit = context.read<ChatSettingsCubit>();
    if (await ModelPickerSheet.show(context)) cubit.modelChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return BlocBuilder<ChatSettingsCubit, ChatSettingsState>(
      builder: (context, state) {
        final connection = state.connection;
        final Widget row = switch ((state.loading, connection)) {
          (true, _) => const _LoadingRow(),
          (false, null) => _ConnectRow(onTap: _connect),
          (false, final ChatConnection c) => _ConnectedRow(
            connection: c,
            onTap: () => _openKeyDialog(c.vendor),
          ),
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RowHighlight(
              play: widget.highlightConnection,
              replayToken: _replay,
              announce: connection == null
                  ? l10n.walkChatConnectTitle
                  : chatVendorName(l10n, connection.vendor),
              child: row,
            ),
            if (connection case final c?) ...[
              _ModelRow(
                state: state,
                onPick: () => unawaited(_pickModel()),
                onRetry: () =>
                    unawaited(context.read<ChatSettingsCubit>().retryModels()),
              ),
              AppListTile(
                key: const Key('settings-chat-change-key'),
                leading: const Icon(Icons.key_outlined),
                title: Text(l10n.walkChatSettingsChange),
                onTap: () => _openKeyDialog(c.vendor),
              ),
              AppListTile(
                key: const Key('settings-chat-switch-vendor'),
                leading: const Icon(Icons.swap_horiz),
                title: Text(l10n.walkChatSettingsSwitchVendor),
                onTap: () => _switchVendor(c.vendor),
              ),
              AppListTile(
                key: const Key('settings-chat-delete'),
                leading: const Icon(Icons.link_off_outlined),
                title: Text(l10n.walkChatSettingsDelete),
                onTap: _disconnect,
              ),
              // 보낼 곳(연결한 벤더)이 정해진 뒤에만 안내한다.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Text(
                  l10n.walkChatSettingsNotice(chatVendorName(l10n, c.vendor)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// 모델 행(스펙 §6.1) — 지금 모델 이름(빠른 출력이면 표시). 누르면 모델 고르기 시트.
/// 목록을 받지 못했으면 "목록을 받지 못했어요 · 다시 시도", 누르면 다시 받는다.
/// 목록을 받는 중엔 제목만(누를 수 없다).
class _ModelRow extends StatelessWidget {
  const _ModelRow({
    required this.state,
    required this.onPick,
    required this.onRetry,
  });

  final ChatSettingsState state;
  final VoidCallback onPick;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final model = state.model;
    final (subtitle, onTap) = switch ((model, state.modelsUnavailable)) {
      (final ModelChipData m, _) => (
        state.fastMode ? l10n.walkChatSettingsModelFast(m.label) : m.label,
        onPick,
      ),
      (null, true) => (l10n.walkChatSettingsModelsUnavailable, onRetry),
      (null, false) => (null, null),
    };
    return AppListTile(
      key: const Key('settings-chat-model'),
      leading: const Icon(Icons.tune),
      title: Text(l10n.walkChatSettingsModel),
      subtitle: subtitle == null ? null : Text(subtitle),
      onTap: onTap,
    );
  }
}

/// 읽는 중 연결 행 — 제목만. 연결돼 있을 수도 있어 '연결하기'를 미리 보이지 않는다.
class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      key: const Key('settings-chat-key'),
      leading: const Icon(Icons.power_outlined),
      title: Text(AppLocalizations.of(context).walkChatConnectTitle),
    );
  }
}

/// 미연결 연결 행.
class _ConnectRow extends StatelessWidget {
  const _ConnectRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppListTile(
      key: const Key('settings-chat-key'),
      leading: const Icon(Icons.power_outlined),
      title: Text(l10n.walkChatConnectTitle),
      subtitle: Text(l10n.walkChatConnectDescription),
      trailing: Text(
        l10n.walkChatConnectAction,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// 연결됨 연결 행 — 벤더 로고 · 이름 · 가린 키 · 확인 상태.
class _ConnectedRow extends StatelessWidget {
  const _ConnectedRow({required this.connection, required this.onTap});

  final ChatConnection connection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, label, color) = switch (connection.status) {
      ChatKeyStatus.valid => (
        Icons.check_circle_outline,
        l10n.walkChatKeyStatusValid,
        scheme.primary,
      ),
      ChatKeyStatus.unverified => (
        null,
        l10n.walkChatKeyStatusUnverified,
        scheme.onSurfaceVariant,
      ),
      ChatKeyStatus.invalid => (
        Icons.error_outline,
        l10n.walkChatKeyStatusInvalid,
        scheme.error,
      ),
    };
    final labelStyle = theme.textTheme.labelLarge?.copyWith(color: color);
    return AppListTile(
      key: const Key('settings-chat-key'),
      leading: ChatVendorIcon(connection.vendor),
      title: Text(chatVendorName(l10n, connection.vendor)),
      subtitle: Text(
        connection.keyPreview,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            // 상태 글자와 같은 높이 — 아이콘 크기 토큰이 없어 글자 토큰을 따른다.
            Icon(icon, size: labelStyle?.fontSize, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(label, style: labelStyle),
        ],
      ),
      onTap: onTap,
    );
  }
}
