import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/chat_model_catalog.dart';
import '../../../domain/chat/chat_settings.dart';
import '../../../domain/chat/usecase/chat_model_choice.dart';
import '../cubit/model_picker_cubit.dart';
import '../cubit/model_picker_state.dart';
import 'chat_vendor_icon.dart';

/// 모델 고르기 시트(키 입력 기획 §6.2): 최신순 모델 행 + 지원 모델이면 빠르게 답하기 스위치.
class ModelPickerSheet extends StatelessWidget {
  const ModelPickerSheet._();

  /// 고르면 저장하고 닫는다. 바뀐 게 있으면 true(바깥을 눌러 닫아도 빠른 출력을 바꿨으면 true).
  static Future<bool> show(BuildContext context) async {
    final cubit = ModelPickerCubit(
      getIt<ChatModelChoice>(),
      getIt<ChatModelCatalog>(),
      getIt<ChatSettings>(),
    );
    try {
      await cubit.load();
      if (!context.mounted) return cubit.state.changed;
      final picked = await showModalBottomSheet<bool>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (_) =>
            BlocProvider.value(value: cubit, child: const ModelPickerSheet._()),
      );
      return picked ?? cubit.state.changed;
    } finally {
      await cubit.close();
    }
  }

  /// 요금 배수: 정수면 '2', 아니면 소수 한 자리(locale 의 소수점).
  static String formatFactor(double factor, String locale) =>
      factor == factor.truncateToDouble()
      ? factor.toInt().toString()
      : NumberFormat('0.0', locale).format(factor);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return BlocBuilder<ModelPickerCubit, ModelPickerState>(
      builder: (context, state) {
        final factor = state.fastModeFactor;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.walkChatModelPickerTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final row in state.rows)
                    _ModelRow(row: row, onTap: () => _select(context, row.id)),
                ],
              ),
            ),
            if (state.fastModeAvailable && factor != null)
              SwitchListTile(
                key: const Key('model-fast-mode'),
                secondary: const Icon(Icons.bolt),
                title: Text(l10n.walkChatFastMode),
                subtitle: Text(
                  l10n.walkChatFastModeSubtitle(
                    formatFactor(factor, l10n.localeName),
                  ),
                ),
                value: state.fastMode,
                onChanged: (on) => _toggleFastMode(context, state, on),
              ),
          ],
        );
      },
    );
  }

  static Future<void> _select(BuildContext context, String id) async {
    final cubit = context.read<ModelPickerCubit>();
    await cubit.select(id);
    if (context.mounted) Navigator.pop(context, cubit.state.changed);
  }

  /// 처음 켤 때만 요금을 확인받는다. 끄기는 묻지 않는다. 시트는 닫지 않는다.
  static Future<void> _toggleFastMode(
    BuildContext context,
    ModelPickerState state,
    bool on,
  ) async {
    final cubit = context.read<ModelPickerCubit>();
    final result = await cubit.toggleFastMode(on);
    if (result != FastModeToggle.needsAck || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.walkChatFastModeConfirmTitle,
      content: l10n.walkChatFastModeConfirmBody(
        chatVendorCompany(l10n, state.company),
        formatFactor(state.fastModeFactor ?? 1, l10n.localeName),
      ),
      confirmLabel: l10n.walkChatFastModeConfirmAction,
      isDestructive: false,
    );
    if (confirmed) await cubit.confirmFastMode();
  }
}

class _ModelRow extends StatelessWidget {
  const _ModelRow({required this.row, required this.onTap});

  final ModelPickerRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final created = row.createdAt;
    final subtitle = [
      if (created != null) DateFormat.yMMMd(l10n.localeName).format(created),
      if (row.noImages) l10n.walkChatModelNoImages,
    ].join(' · ');
    return AppListTile(
      key: Key('model-row-${row.id}'),
      title: Text(row.label),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          if (row.recommended) _Badge(l10n.walkChatModelRecommended),
          if (row.isNew) _Badge(l10n.walkChatModelNew),
          if (row.inUse)
            Icon(Icons.check, semanticLabel: l10n.walkChatModelInUse),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// 행 오른쪽의 작은 글 배지(추천 · NEW). 이 시트에서만 쓴다.
class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: AppRadius.smAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
