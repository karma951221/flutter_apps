import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../cubit/diary_settings_cubit.dart';
import '../widget/diary_storage_section.dart';

/// 일기 설정 — 휴지통 보관 기간 · 저장 공간. 잠금 아래 화면이다(`openSettings` 가
/// `pushDiaryRoute` 로 연다). 열릴 때 [DiarySettingsCubit] 을 다시 읽는다.
class DiarySettingsPage extends StatefulWidget {
  const DiarySettingsPage({super.key});

  @override
  State<DiarySettingsPage> createState() => _DiarySettingsPageState();
}

class _DiarySettingsPageState extends State<DiarySettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<DiarySettingsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.walkDiarySettingsTitle)),
      body: ListView(children: const [DiaryStorageSection()]),
    );
  }
}
