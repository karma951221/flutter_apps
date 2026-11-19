import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/diary/draft/draft_style.dart';
import '../../diary/draft/draft_style_text.dart';
import '../cubit/diary_settings_cubit.dart';
import '../cubit/diary_settings_state.dart';
import 'settings_widgets.dart';

/// 일기 설정 › 자동 초안 — 문체 · "사진 보여 주기"(스펙 2026-11-15 §4 R-A2 · R-A4) ·
/// 저장할 때 AI 스토리 고르기(2026-11-19).
/// 문체는 여기서만 고른다. 사진 보여 주기는 작성 화면 도구줄의 토글과 같은 값이다.
class DiaryDraftSection extends StatelessWidget {
  const DiaryDraftSection({super.key});

  Future<void> _pickStyle(BuildContext context, DraftStyle current) async {
    final l10n = AppLocalizations.of(context);
    final settings = context.read<DiarySettingsCubit>();
    final picked = await SettingsChoiceSheet.show<DraftStyle>(
      context,
      title: l10n.walkDiaryDraftSettingsStyle,
      current: current,
      options: [
        for (final style in DraftStyle.values)
          (
            style,
            l10n.walkDiaryDraftStyleOption(
              draftStyleName(l10n, style),
              draftStyleExample(l10n, style),
            ),
          ),
      ],
    );
    if (picked == null) return;
    await settings.setDraftStyle(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<DiarySettingsCubit, DiarySettingsState>(
      buildWhen: (a, b) =>
          a.draftStyle != b.draftStyle ||
          a.draftIncludePhotos != b.draftIncludePhotos ||
          a.storyAi != b.storyAi,
      builder: (context, state) {
        final cubit = context.read<DiarySettingsCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(l10n.walkDiaryDraftSettingsSection),
            AppListTile(
              key: const Key('settings-diary-draft-style'),
              leading: const Icon(Icons.auto_awesome_outlined),
              title: Text(l10n.walkDiaryDraftSettingsStyle),
              trailing: Text(draftStyleName(l10n, state.draftStyle)),
              onTap: () => _pickStyle(context, state.draftStyle),
            ),
            AppSwitchTile(
              key: const Key('settings-diary-draft-photos'),
              leading: const Icon(Icons.photo_outlined),
              title: Text(l10n.walkDiaryDraftIncludePhotos),
              subtitle: Text(
                l10n.walkDiaryDraftSettingsIncludePhotosDescription,
              ),
              value: state.draftIncludePhotos,
              onChanged: cubit.setDraftIncludePhotos,
            ),
            AppSwitchTile(
              key: const Key('settings-diary-story-ai'),
              leading: const Icon(Icons.auto_stories_outlined),
              title: Text(l10n.walkDiaryStoryAiSetting),
              subtitle: Text(l10n.walkDiaryStoryAiSettingDescription),
              value: state.storyAi,
              onChanged: cubit.setStoryAi,
            ),
          ],
        );
      },
    );
  }
}
