import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/alarm/entity/alarm.dart';
import '../../../domain/alarm/entity/alarm_sound.dart';
import '../../../domain/alarm/permission/alarm_permissions.dart';
import '../../../domain/alarm/usecase/alarm_use_case.dart';
import '../../../domain/backup/backup_area_id.dart';
import '../../../domain/backup/backup_area_source.dart';
import '../../../domain/backup/restore_notice.dart';
import '../../alarm/archive/ring_archive_database.dart';
import '../../alarm/prefs_alarm_repository.dart';
import '../../settings/prefs_settings_repository.dart';
import 'area_io.dart';
import 'dir_swap.dart';
import 'drift_rows.dart';
import 'prefs_snapshot.dart';

const _dataFile = 'data.json';
const _archiveFile = 'ring_archive.json';
const _sounds = 'sounds';

/// 알람 영역이 담는 prefs. 고장 사본(`walk.alarms.corrupt`)은 일시 상태라 담지 않는다.
const _prefKeys = {
  PrefsAlarmRepository.key,
  PrefsSettingsRepository.holidayReminderKey,
  PrefsSettingsRepository.pauseFromKey,
  PrefsSettingsRepository.pauseUntilKey,
};

/// 알람 영역. `alarm/data.json`(알람 목록 · 공휴일 알림 · 쉬는 기간 prefs) ·
/// `alarm/sounds/`(기기 알람음 · 내 파일 사본) · `alarm/ring_archive.json`(울림 보관 행)을 쓴다.
///
/// 복원하면 기기 소리 · 내 파일 알람의 경로를 지금 기기의 [_soundsDir] 로 다시 맞춘다 —
/// 절대 경로는 기기 · 사용자마다 다르다. 사본이 백업에 없으면 기본 알람음으로 바꾼다.
class AlarmBackupArea implements BackupAreaSource {
  /// [_soundsDir] 는 `getDir("flutter")/alarm_sounds` = 문서 폴더의 `alarm_sounds/`.
  AlarmBackupArea(
    this._prefs,
    this._archive,
    this._soundsDir,
    this._alarms,
    this._permissions,
  );

  final SharedPreferences _prefs;
  final RingArchiveDatabase _archive;
  final Directory _soundsDir;
  final AlarmUseCase _alarms;
  final AlarmPermissions _permissions;

  /// 마지막 [replace] 가 사본 없는 알람음을 기본 알람음으로 바꿨는가. [afterRestore] 가 알린다.
  bool _soundFellBack = false;

  Directory _areaDir(Directory root) => Directory('${root.path}/${id.name}');

  @override
  BackupAreaId get id => BackupAreaId.alarm;

  @override
  Map<String, int> get schema => {
    'ringArchive': _archive.schemaVersion,
    'alarmsJson': 1,
  };

  @override
  Future<Map<String, int>> counts() async {
    await _reload();
    return {'alarms': _storedAlarms().length};
  }

  /// 알람음 사본 크기의 합. prefs · 울림 기록은 그에 비해 작아 넣지 않는다.
  @override
  Future<int> estimatedBytes() async {
    var total = 0;
    for (final f in await _soundFiles(_soundsDir)) {
      total += await f.length();
    }
    return total;
  }

  @override
  Future<Map<String, int>> export(Directory root) async {
    final out = _areaDir(root);
    final sounds = Directory('${out.path}/$_sounds');
    await createFilesFolder(sounds);

    await _reload();
    await writeAreaJson(out, _dataFile, await dumpPrefs(_prefs, _prefKeys));
    await writeAreaJson(
      out,
      _archiveFile,
      await dumpTables(_archive, [_archive.archivedRings]),
    );
    for (final f in await _soundFiles(_soundsDir)) {
      await f.copy('${sounds.path}/${p.basename(f.path)}');
    }

    return {'alarms': _storedAlarms().length};
  }

  @override
  Future<void> validate(Directory root) async {
    await _readArchive(root);
    await readPrefsSnapshot(_areaDir(root), _dataFile, _prefKeys);
  }

  @override
  Future<void> replace(Directory root) async {
    final rows = await _readArchive(root);
    final prefs = await readPrefsSnapshot(_areaDir(root), _dataFile, _prefKeys);
    final incoming = Directory('${_areaDir(root).path}/$_sounds');
    // 폴더가 없으면 이미 옮겨 간 것이다 — 지금 폴더의 사본을 기준으로 경로만 맞춘다.
    await dropFilesFolderMarker(incoming);
    final source = await incoming.exists() ? incoming : _soundsDir;
    final available = {
      for (final f in await _soundFiles(source)) p.basename(f.path),
    };
    _soundFellBack = false;
    final relocated = _relocateSounds(prefs, available);
    final table = _archive.archivedRings;
    await replaceFilesFolder(_soundsDir, incoming, () async {
      await _archive.transaction(() async {
        await deleteAllRows(_archive, table);
        await insertRows(_archive, table, rows[table.actualTableName]!);
      });
    });

    await restorePrefs(_prefs, _prefKeys, relocated);
  }

  /// 알람을 다시 예약하고 다음 알람 위젯 · 미리 알림을 새로 맞춘다. 알람음을 기본으로
  /// 바꿨거나, 알람이 있는데 울리는 데 필요한 권한이 꺼져 있거나, 다시 예약이 실패하면 알린다.
  @override
  Future<Set<RestoreNotice>> afterRestore() async {
    var resynced = true;
    try {
      await _alarms.sync();
    } on Object catch (e, s) {
      debugPrint('alarm resync after restore failed: $e\n$s');
      resynced = false;
    }
    final fellBack = _soundFellBack;
    _soundFellBack = false;
    await _reload();
    return {
      if (!resynced) RestoreNotice.alarmResyncFailed,
      if (fellBack) RestoreNotice.alarmSoundFallback,
      if (_storedAlarms().isNotEmpty && !await _permissions.canRing())
        RestoreNotice.alarmPermissionNeeded,
    };
  }

  /// 다른 isolate(헤드리스 엔진)가 바꾼 알람을 놓치지 않게 디스크에서 다시 읽는다.
  Future<void> _reload() async {
    try {
      await _prefs.reload();
    } on Object {
      // 다시 읽지 못하면 가진 사본으로 읽는다.
    }
  }

  /// 저장된 알람 목록의 항목들. 읽을 수 없으면 비어 있다(저장소와 같은 규칙).
  List<Object?> _storedAlarms() {
    final raw = _prefs.get(PrefsAlarmRepository.key);
    if (raw is! String) return const [];
    try {
      return switch (jsonDecode(raw)) {
        final List<Object?> items => items,
        _ => const [],
      };
    } on FormatException {
      return const [];
    }
  }

  /// [snapshot] 의 알람 목록에서 기기 소리 · 내 파일 경로를 [_soundsDir] 의 같은 이름으로
  /// 바꾼다. [available] 에 그 이름이 없으면 기본 알람음으로 바꾼다. 알람 저장소의
  /// 직렬화([Alarm.fromJson] · [Alarm.toJson])를 거친다. 읽지 못하는 항목은 그대로 둔다 —
  /// 저장소가 읽을 때 고장 사본을 남기고 건너뛴다.
  Map<String, Object?> _relocateSounds(
    Map<String, Object?> snapshot,
    Set<String> available,
  ) {
    const key = PrefsAlarmRepository.key;
    final Object? items;
    switch (snapshot[key]) {
      case {'type': 'string', 'value': final String raw}:
        try {
          items = jsonDecode(raw);
        } on FormatException {
          return snapshot;
        }
      default:
        return snapshot;
    }
    if (items is! List<Object?>) return snapshot;

    final relocated = [
      for (final item in items) _relocateAlarm(item, available) ?? item,
    ];
    return {
      ...snapshot,
      key: {'type': 'string', 'value': jsonEncode(relocated)},
    };
  }

  /// 소리 경로를 바꾼 알람의 JSON. 알람으로 읽을 수 없으면 null.
  Map<String, Object?>? _relocateAlarm(Object? item, Set<String> available) {
    final Alarm alarm;
    try {
      alarm = Alarm.fromJson(item! as Map<String, Object?>);
    } on Object {
      return null;
    }
    String? local(String path) {
      final name = p.basename(path);
      if (available.contains(name)) return '${_soundsDir.path}/$name';
      _soundFellBack = true;
      return null;
    }

    final sound = switch (alarm.sound) {
      DeviceAlarmSound(:final title, :final path) => switch (local(path)) {
        final String path => AlarmSound.device(title: title, path: path),
        null => const AlarmSound.system(),
      },
      FileAlarmSound(:final title, :final path) => switch (local(path)) {
        final String path => AlarmSound.file(title: title, path: path),
        null => const AlarmSound.system(),
      },
      final other => other,
    };
    return alarm.copyWith(sound: sound).toJson();
  }

  /// [dir] 바로 아래의 파일들. 링크는 따라가지 않는다 — 폴더 밖을 가리킬 수 있다.
  Future<List<File>> _soundFiles(Directory dir) async {
    if (!await dir.exists()) return const [];
    return [
      await for (final f in dir.list(followLinks: false))
        if (f is File) f,
    ];
  }

  Future<TableRows> _readArchive(Directory root) =>
      readTableRows(_areaDir(root), _archiveFile, [_archive.archivedRings]);
}
