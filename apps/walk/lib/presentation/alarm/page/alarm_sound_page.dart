import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../../domain/alarm/entity/alarm_sound.dart';
import '../../../domain/alarm/sound/alarm_sound_source.dart';
import '../cubit/alarm_sound_cubit.dart';
import '../cubit/alarm_sound_state.dart';
import '../format/alarm_sound_format.dart';

/// 알람음 선택. 시스템 기본 · 앱 소리 · 기기 알람음 · 내 파일 구역에서 고르고 미리 듣는다.
/// "선택" 하면 고른 [AlarmSound] 를 결과로 돌려주며 닫힌다. 뒤로 가면 결과는 null.
class AlarmSoundPage extends StatefulWidget {
  const AlarmSoundPage({required this.initial, super.key});

  final AlarmSound initial;

  @override
  State<AlarmSoundPage> createState() => _AlarmSoundPageState();
}

class _AlarmSoundPageState extends State<AlarmSoundPage> {
  late final _cubit = AlarmSoundCubit(getIt<AlarmSoundSource>(), widget.initial)
    ..load();

  /// 홈 · 화면 잠금으로 앱이 가려지면 미리 듣기를 멈춘다. 화면은 그대로 두므로 dispose 로는 못 잡는다.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: _cubit.pausePreview);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    try {
      final sound = await _cubit.confirm();
      if (mounted) Navigator.of(context).pop(sound);
    } on Object {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: l10n.walkAlarmSoundImportFailed,
        type: AppSnackBarType.error,
      );
    }
  }

  /// 기기의 오디오 파일을 고른다. 취소는 조용히, 실패(너무 큼 · 재생 불가)만 안내한다.
  Future<void> _pickFile() async {
    final l10n = AppLocalizations.of(context);
    final result = await _cubit.pickFile(
      fallbackTitle: l10n.walkAlarmSoundFileDefaultTitle,
    );
    if (result != PickFileResult.failed || !mounted) return;
    AppSnackBar.show(
      context,
      message: l10n.walkAlarmSoundFileFailed,
      type: AppSnackBarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<AlarmSoundCubit, AlarmSoundState>(
      bloc: _cubit,
      builder: (context, state) {
        Widget row(String title, AlarmSoundChoice choice) => AppSelectTile(
          title: Text(title),
          selected: state.selected == choice,
          onTap: state.importing ? null : () => _cubit.select(choice),
        );
        return Scaffold(
          appBar: AppBar(title: Text(l10n.walkAlarmSound)),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    children: [
                      AppSectionHeader(l10n.walkAlarmSoundDefaultSection),
                      row(
                        l10n.walkAlarmSoundSystem,
                        const AlarmSoundChoice.system(),
                      ),
                      AppSectionHeader(l10n.walkAlarmSoundBundledSection),
                      for (final asset in BundledAlarmSounds.all)
                        row(
                          AlarmSoundFormat.bundled(l10n, asset),
                          AlarmSoundChoice.bundled(asset),
                        ),
                      AppSectionHeader(l10n.walkAlarmSoundDeviceSection),
                      ...switch (state.ringtones) {
                        DeviceRingtonesLoading() => const [
                          SizedBox(
                            height: AppSpacing.xl * 3,
                            child: AppLoading(),
                          ),
                        ],
                        DeviceRingtonesLoaded(:final items)
                            when items.isNotEmpty =>
                          [
                            for (final ringtone in items)
                              row(
                                ringtone.title,
                                AlarmSoundChoice.device(ringtone),
                              ),
                          ],
                        DeviceRingtonesLoaded() || DeviceRingtonesFailure() => [
                          AppPlaceholder(
                            icon: Icons.music_off_outlined,
                            message: l10n.walkAlarmSoundDeviceUnavailable,
                          ),
                        ],
                      },
                      AppSectionHeader(l10n.walkAlarmSoundFileSection),
                      if (state.myFile case final FileAlarmSound myFile)
                        row(myFile.title, AlarmSoundChoice.file(myFile)),
                      AppListTile(
                        leading: const Icon(Icons.audio_file_outlined),
                        title: Text(l10n.walkAlarmSoundPickFile),
                        onTap: state.importing ? null : _pickFile,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: AppButton.primary(
                      label: l10n.walkAlarmSoundSelect,
                      isLoading: state.importing,
                      onPressed: _confirm,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
