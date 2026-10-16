import 'dart:convert';

import 'package:core/core.dart';

import '../../dog/entity/dog.dart';
import '../../walk/entity/geo_point.dart';
import '../../walk/entity/walk.dart';
import '../../walk/entity/walk_photo.dart';
import '../../walk/entity/walk_track_point.dart';
import '../../walk/policy/route_preview.dart';
import '../entity/backup_data.dart';

/// `backup.json` 을 손으로 쓰고 읽는 순수 함수 모음.
///
/// 시각은 UTC ISO-8601, `birthday` 는 날짜만(`yyyy-MM-dd`). `previewPoints` 는
/// 싣지 않고 읽을 때 점으로 다시 만든다. [decode] 는 던지지 않는다 — 형식이
/// 하나라도 어긋나면 아무것도 돌려주지 않고 `Err` 다(반쯤 읽은 값을 쓰지 않게).
abstract final class BackupCodec {
  static const format = 'pawlog-backup';
  static const version = 1;

  static final _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// 시간대가 적히지 않은 시각은 기기마다 다른 순간이 되므로 받지 않는다.
  static final _zonePattern = RegExp(r'(Z|[+-]\d{2}(:?\d{2})?)$');

  static String encode(BackupData data) => jsonEncode({
    'format': format,
    'version': version,
    'exportedAt': _instant(data.exportedAt),
    'dogs': [for (final dog in data.dogs) _encodeDog(dog)],
    'walks': [for (final walk in data.walks) _encodeWalk(walk)],
  });

  static Result<BackupData> decode(String json) {
    try {
      return Ok(_decode(jsonDecode(json)));
    } on FormatException catch (e) {
      return _invalid(e.message);
    } on TypeError catch (e) {
      return _invalid(e.toString());
    } on _InvalidBackup catch (e) {
      return _invalid(e.reason);
    }
  }

  static Err<BackupData> _invalid(String reason) => Err(
    Failure.validation(
      message: '백업 파일을 읽지 못했어요: $reason',
      failureCode: FailureCode.invalidData,
    ),
  );

  // ── encode ──

  static String _instant(DateTime t) => t.toUtc().toIso8601String();

  /// DB 와 같이 현지 날짜 성분을 그대로 쓴다.
  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Map<String, Object?> _encodeDog(Dog dog) => {
    'id': dog.id,
    'name': dog.name,
    'breed': dog.breed,
    'birthday': dog.birthday == null ? null : _date(dog.birthday!),
    'photoPath': dog.photoPath,
    'createdAt': _instant(dog.createdAt),
    'updatedAt': _instant(dog.updatedAt),
  };

  static Map<String, Object?> _encodeWalk(BackupWalk backup) {
    final walk = backup.walk;
    return {
      'id': walk.id,
      'startedAt': _instant(walk.startedAt),
      'endedAt': _instant(walk.endedAt),
      'durationSeconds': walk.duration.inSeconds,
      'distanceMeters': walk.distanceMeters,
      'memo': walk.memo,
      'dogIds': [for (final dog in walk.dogs) dog.id],
      'photos': [
        for (final photo in walk.photos)
          {'id': photo.id, 'path': photo.path, 'position': photo.position},
      ],
      'createdAt': _instant(walk.createdAt),
      'updatedAt': _instant(walk.updatedAt),
      'points': [
        for (final p in backup.points)
          {
            'lat': p.point.lat,
            'lng': p.point.lng,
            'recordedAt': _instant(p.recordedAt),
            'accuracy': p.accuracy,
          },
      ],
    };
  }

  // ── decode ──

  static BackupData _decode(Object? root) {
    final map = _map(root, 'root');
    if (map['format'] != format) throw const _InvalidBackup('format');
    final v = map['version'];
    if (v is! num || v != version) throw _InvalidBackup('version $v');
    final dogs = [
      for (final e in _list(map, 'dogs')) _decodeDog(_map(e, 'dog')),
    ];
    _requireUnique('dog', [for (final dog in dogs) dog.id]);
    final dogsById = {for (final dog in dogs) dog.id: dog};
    final walks = [
      for (final e in _list(map, 'walks'))
        _decodeWalk(_map(e, 'walk'), dogsById),
    ];
    _requireUnique('walk', [for (final w in walks) w.walk.id]);
    _requireUnique('photo', [
      for (final w in walks)
        for (final photo in w.walk.photos) photo.id,
    ]);
    return BackupData(
      exportedAt: _parseInstant(map, 'exportedAt'),
      dogs: dogs,
      walks: walks,
    );
  }

  /// 같은 id 가 두 번 나오면 어느 쪽을 믿을지 정할 수 없으니 통째로 읽지 않는다.
  static void _requireUnique(String what, List<String> ids) {
    final seen = <String>{};
    for (final id in ids) {
      if (!seen.add(id)) throw _InvalidBackup('duplicate $what id $id');
    }
  }

  static Dog _decodeDog(Map<String, Object?> m) => Dog(
    id: _string(m, 'id'),
    name: _string(m, 'name'),
    breed: _optionalString(m, 'breed'),
    birthday: _parseDate(m['birthday']),
    photoPath: _optionalString(m, 'photoPath'),
    createdAt: _parseInstant(m, 'createdAt'),
    updatedAt: _parseInstant(m, 'updatedAt'),
  );

  static BackupWalk _decodeWalk(
    Map<String, Object?> m,
    Map<String, Dog> dogsById,
  ) {
    final points = [
      for (final e in _list(m, 'points')) _decodePoint(_map(e, 'point')),
    ];
    final dogs = [
      for (final id in _list(m, 'dogIds'))
        dogsById[id] ?? (throw _InvalidBackup('unknown dogId $id')),
    ];
    return BackupWalk(
      walk: Walk(
        id: _string(m, 'id'),
        startedAt: _parseInstant(m, 'startedAt'),
        endedAt: _parseInstant(m, 'endedAt'),
        duration: Duration(seconds: _int(m, 'durationSeconds')),
        distanceMeters: _num(m, 'distanceMeters').toDouble(),
        memo: _optionalString(m, 'memo'),
        dogs: dogs,
        photos: [
          for (final e in _list(m, 'photos')) _decodePhoto(_map(e, 'photo')),
        ],
        previewPoints: RoutePreview.downsample(points),
        createdAt: _parseInstant(m, 'createdAt'),
        updatedAt: _parseInstant(m, 'updatedAt'),
      ),
      points: points,
    );
  }

  static WalkPhoto _decodePhoto(Map<String, Object?> m) => WalkPhoto(
    id: _string(m, 'id'),
    path: _string(m, 'path'),
    position: _int(m, 'position'),
  );

  static WalkTrackPoint _decodePoint(Map<String, Object?> m) => WalkTrackPoint(
    point: GeoPoint(
      lat: _num(m, 'lat').toDouble(),
      lng: _num(m, 'lng').toDouble(),
    ),
    recordedAt: _parseInstant(m, 'recordedAt'),
    accuracy: (m['accuracy'] as num?)?.toDouble(),
  );

  // ── 필드 읽기: 없거나 타입이 다르면 _InvalidBackup ──

  static Map<String, Object?> _map(Object? value, String what) {
    if (value is Map<String, Object?>) return value;
    throw _InvalidBackup('$what is not an object');
  }

  static List<Object?> _list(Map<String, Object?> m, String key) {
    final value = m[key];
    if (value is List<Object?>) return value;
    throw _InvalidBackup('$key is not a list');
  }

  static String _string(Map<String, Object?> m, String key) {
    final value = m[key];
    if (value is String) return value;
    throw _InvalidBackup('$key is not a string');
  }

  static String? _optionalString(Map<String, Object?> m, String key) {
    final value = m[key];
    if (value == null || value is String) return value as String?;
    throw _InvalidBackup('$key is not a string');
  }

  static num _num(Map<String, Object?> m, String key) {
    final value = m[key];
    if (value is num) return value;
    throw _InvalidBackup('$key is not a number');
  }

  static int _int(Map<String, Object?> m, String key) {
    final value = m[key];
    if (value is int) return value;
    throw _InvalidBackup('$key is not an integer');
  }

  static DateTime _parseInstant(Map<String, Object?> m, String key) {
    final raw = _string(m, key);
    if (!_zonePattern.hasMatch(raw)) throw _InvalidBackup('$key has no zone');
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) throw _InvalidBackup('$key is not a timestamp');
    return parsed.toUtc();
  }

  /// DB 처럼 현지 자정으로 되살린다. `2020-02-30` 같은 없는 날짜는 받지 않는다.
  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    final match = raw is String ? _datePattern.firstMatch(raw) : null;
    if (match == null) throw _InvalidBackup('birthday $raw');
    final y = int.parse(match[1]!);
    final mo = int.parse(match[2]!);
    final d = int.parse(match[3]!);
    final date = DateTime(y, mo, d);
    if (date.year != y || date.month != mo || date.day != d) {
      throw _InvalidBackup('birthday $raw');
    }
    return date;
  }
}

final class _InvalidBackup implements Exception {
  const _InvalidBackup(this.reason);
  final String reason;
}
