import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/chat/chat_settings.dart';
import '../../../domain/chat/chat_vendor.dart';
import '../../../domain/diary/draft/draft_context.dart';
import '../../../domain/diary/draft/draft_style.dart';
import '../../../domain/diary/draft/draft_writer.dart';
import '../../../domain/diary/entity/entry_media.dart';
import '../../../domain/diary/repository/diary_preferences.dart';
import '../../chat/widget/chat_failure_text.dart';
import '../../chat/widget/chat_vendor_icon.dart';
import 'draft_cubit.dart';
import 'draft_state.dart';
import 'draft_style_text.dart';

/// 초안 시트(스펙 §4 A1~A3). 성공하면 초안 글을, 닫거나 손으로 쓰기로 돌아가면 null 을 돌려준다.
///
/// - [initialMemo]: 메모 칸에 미리 채울 글(작성 화면에 이미 쓴 짧은 글).
/// - [contextFor]: 시트에서 고친 메모로 [DraftContext] 를 만든다(시각 · 장소 · 개수 · 촬영 범위 · 태그는 부르는 쪽 몫).
/// - [photos]: 붙인 미디어. 사진이 하나라도 있을 때만 "사진도 보여 주기" 스위치를 보인다.
/// - [onOpenChatSettings]: 키가 없을 때 [설정 열기] — 시트를 닫은 뒤 부른다. null 이면 버튼 없이 안내만.
///
/// [DraftWriter] · [DiaryPreferences] · [ChatSettings] 는 getIt 에서 읽는다.
Future<String?> showDraftSheet(
  BuildContext context, {
  required String initialMemo,
  required DraftContext Function(String memo) contextFor,
  required List<EntryMedia> photos,
  VoidCallback? onOpenChatSettings,
}) async {
  var openSettings = false;
  final text = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider(
      create: (_) => DraftCubit(
        getIt<DraftWriter>(),
        getIt<DiaryPreferences>(),
        getIt<ChatSettings>(),
      )..load(),
      child: DraftSheet(
        initialMemo: initialMemo,
        contextFor: contextFor,
        photos: photos,
        onOpenChatSettings: onOpenChatSettings == null
            ? null
            : () => openSettings = true,
      ),
    ),
  );
  if (openSettings) onOpenChatSettings?.call();
  return text;
}

class DraftSheet extends StatefulWidget {
  const DraftSheet({
    required this.initialMemo,
    required this.contextFor,
    required this.photos,
    this.onOpenChatSettings,
    super.key,
  });

  final String initialMemo;
  final DraftContext Function(String memo) contextFor;
  final List<EntryMedia> photos;

  /// 시트를 닫기 직전에 부른다(실제 화면 열기는 [showDraftSheet] 가 닫힌 뒤).
  final VoidCallback? onOpenChatSettings;

  @override
  State<DraftSheet> createState() => _DraftSheetState();
}

class _DraftSheetState extends State<DraftSheet> {
  late final _memo = TextEditingController(text: widget.initialMemo);

  bool get _hasPhotos => widget.photos.any((m) => m.kind == MediaKind.photo);

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  Future<void> _write() async {
    final cubit = context.read<DraftCubit>();
    if (cubit.state.availability case DraftConsentNeeded(:final vendor)) {
      final l10n = AppLocalizations.of(context);
      final accepted = await AppConfirmDialog.show(
        context,
        title: l10n.walkDiaryDraftConsentTitle,
        content: l10n.walkChatConsentNotice(chatVendorName(l10n, vendor)),
        confirmLabel: l10n.walkChatConsentAccept,
        isDestructive: false,
      );
      if (!accepted || !mounted) return;
      await cubit.consent();
      if (!mounted || cubit.state.availability is! DraftReady) return;
    }
    await cubit.write(widget.contextFor(_memo.text), widget.photos);
  }

  void _openSettings() {
    widget.onOpenChatSettings?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return BlocConsumer<DraftCubit, DraftState>(
      listenWhen: (a, b) => a.run != b.run,
      listener: (context, state) {
        if (state.run case DraftRunDone(:final text)) {
          Navigator.of(context).pop(text);
        }
      },
      builder: (context, state) {
        final cubit = context.read<DraftCubit>();
        final writing = state.run is DraftRunWriting;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.walkDiaryDraftTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    key: const Key('draft-memo'),
                    controller: _memo,
                    enabled: !writing,
                    maxLines: 1,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: l10n.walkDiaryDraftMemoHint,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final style in DraftStyle.values)
                        ChoiceChip(
                          key: Key('draft-style-${style.name}'),
                          label: Text(draftStyleName(l10n, style)),
                          selected: state.style == style,
                          onSelected: writing
                              ? null
                              : (_) => cubit.setStyle(style),
                        ),
                    ],
                  ),
                  if (_hasPhotos)
                    AppListTile(
                      key: const Key('draft-photos'),
                      title: Text(l10n.walkDiaryDraftIncludePhotos),
                      trailing: Switch(
                        value: state.includePhotos,
                        onChanged: writing ? null : cubit.setIncludePhotos,
                      ),
                      onTap: writing
                          ? null
                          : () => cubit.setIncludePhotos(!state.includePhotos),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  ..._action(context, l10n, state, writing),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _action(
    BuildContext context,
    AppLocalizations l10n,
    DraftState state,
    bool writing,
  ) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final cubit = context.read<DraftCubit>();
    final ChatVendor vendor;
    switch (state.availability) {
      case null:
        return const [Center(child: CircularProgressIndicator())];
      case DraftNoKey():
        return [
          Text(l10n.walkDiaryDraftNoKey, style: theme.textTheme.bodyMedium),
          if (widget.onOpenChatSettings != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(
              label: l10n.walkDiaryDraftOpenSettings,
              onPressed: _openSettings,
            ),
          ],
        ];
      case DraftConsentNeeded(vendor: final v) || DraftReady(vendor: final v):
        vendor = v;
    }
    final name = chatVendorName(l10n, vendor);
    final sendsPhotos = _hasPhotos && state.includePhotos;
    return [
      Text(
        sendsPhotos
            ? l10n.walkDiaryDraftNoticeWithPhotos(name)
            : l10n.walkDiaryDraftNotice(name),
        style: muted,
      ),
      if (state.run case DraftRunFailed(:final failure)) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          chatFailureText(l10n, failure),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        Text(l10n.walkDiaryDraftManualHint, style: muted),
      ],
      const SizedBox(height: AppSpacing.sm),
      if (writing) ...[
        Row(
          children: [
            const SizedBox.square(
              dimension: AppSpacing.md,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l10n.walkDiaryDraftWriting)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.secondary(
          label: l10n.walkDiaryDraftStop,
          onPressed: cubit.stop,
        ),
      ] else
        AppButton.primary(
          key: const Key('draft-write'),
          label: l10n.walkDiaryDraftWrite,
          onPressed: _write,
        ),
    ];
  }
}
