import 'package:freezed_annotation/freezed_annotation.dart';

import 'backup_area_id.dart';

part 'backup_manifest.freezed.dart';

/// 백업 zip 맨 앞의 `manifest.json`. 무엇이 어떤 스키마로 담겼는지와 모든 파일의 무결성 값을 가진다.
@freezed
class BackupManifest with _$BackupManifest {
  /// 이 앱이 쓰는 `format` 값.
  static const formatName = 'lifelog.backup';

  /// 이 앱이 읽을 수 있는 가장 큰 `formatVersion`.
  static const currentFormatVersion = 1;

  @override
  final String format;

  @override
  final int formatVersion;

  @override
  final String appVersion;

  /// 만든 시각. JSON 에는 UTC(`…Z`)로 쓰고, 읽을 때는 화면에 보일 현지 시각으로 바꾼다.
  @override
  final DateTime createdAt;

  @override
  final Map<BackupAreaId, AreaManifest> areas;

  /// JSON 을 포함한 모든 파일. `pack` 이 채우므로 쓰기 전에는 비워 둔다.
  @override
  final List<ManifestFile> files;

  const BackupManifest({
    required this.format,
    required this.formatVersion,
    required this.appVersion,
    required this.createdAt,
    required this.areas,
    required this.files,
  });

  /// 알 수 없는 영역 키는 버린다(더 새 앱이 만든 백업을 읽을 때).
  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    final areas = <BackupAreaId, AreaManifest>{};
    final rawAreas = json['areas'] as Map<String, dynamic>? ?? const {};
    for (final id in BackupAreaId.values) {
      final raw = rawAreas[id.name];
      if (raw != null) {
        areas[id] = AreaManifest.fromJson(raw as Map<String, dynamic>);
      }
    }
    return BackupManifest(
      format: json['format'] as String,
      formatVersion: json['formatVersion'] as int,
      appVersion: json['appVersion'] as String,
      // 오프셋이 없는 예전 값은 그 기기의 현지 시각으로 읽힌다.
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      areas: areas,
      files: [
        for (final f in json['files'] as List<dynamic>? ?? const [])
          ManifestFile.fromJson(f as Map<String, dynamic>),
      ],
    );
  }
}

extension BackupManifestJson on BackupManifest {
  Map<String, dynamic> toJson() => {
    'format': format,
    'formatVersion': formatVersion,
    'appVersion': appVersion,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'areas': {for (final e in areas.entries) e.key.name: e.value.toJson()},
    'files': [for (final f in files) f.toJson()],
  };
}

/// 한 영역의 스키마 버전과 개수(복원 전 미리보기용).
@freezed
class AreaManifest with _$AreaManifest {
  @override
  final Map<String, int> schema;

  @override
  final Map<String, int> counts;

  const AreaManifest({required this.schema, this.counts = const {}});

  factory AreaManifest.fromJson(Map<String, dynamic> json) => AreaManifest(
    schema: _intMap(json['schema']),
    counts: _intMap(json['counts']),
  );
}

extension AreaManifestJson on AreaManifest {
  Map<String, dynamic> toJson() => {'schema': schema, 'counts': counts};
}

/// zip 안 파일 하나의 경로 · 크기 · sha256(소문자 16진수).
@freezed
class ManifestFile with _$ManifestFile {
  @override
  final String path;

  @override
  final int bytes;

  @override
  final String sha256;

  const ManifestFile({
    required this.path,
    required this.bytes,
    required this.sha256,
  });

  factory ManifestFile.fromJson(Map<String, dynamic> json) => ManifestFile(
    path: json['path'] as String,
    bytes: json['bytes'] as int,
    sha256: json['sha256'] as String,
  );
}

extension ManifestFileJson on ManifestFile {
  Map<String, dynamic> toJson() => {
    'path': path,
    'bytes': bytes,
    'sha256': sha256,
  };
}

Map<String, int> _intMap(Object? raw) => {
  for (final e in (raw as Map<String, dynamic>? ?? const {}).entries)
    e.key: e.value as int,
};
