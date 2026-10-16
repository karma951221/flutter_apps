import 'package:intl/intl.dart';

import '../../walk/entity/walk_track_point.dart';

/// 산책 한 건을 GPX 1.1 문서로 바꾸는 순수 함수 모음.
abstract final class GpxEncoder {
  static String encode({
    required String name,
    String? description,
    required DateTime startedAt,
    required List<WalkTrackPoint> points,
  }) {
    final escapedName = _escape(name);
    final memo = description?.trim() ?? '';
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln(
        '<gpx version="1.1" creator="pawlog" '
        'xmlns="http://www.topografix.com/GPX/1/1">',
      )
      ..writeln(
        '  <metadata><name>$escapedName</name>'
        '<time>${_time(startedAt)}</time></metadata>',
      )
      ..writeln('  <trk>')
      ..writeln('    <name>$escapedName</name>');
    if (memo.isNotEmpty) {
      buffer.writeln('    <desc>${_escape(description!)}</desc>');
    }
    buffer
      ..writeln('    <type>walking</type>')
      ..writeln('    <trkseg>');
    for (final p in points) {
      buffer.writeln(
        '      <trkpt lat="${p.point.lat.toStringAsFixed(6)}" '
        'lon="${p.point.lng.toStringAsFixed(6)}">'
        '<time>${_time(p.recordedAt)}</time></trkpt>',
      );
    }
    buffer
      ..writeln('    </trkseg>')
      ..writeln('  </trk>')
      ..writeln('</gpx>');
    return buffer.toString();
  }

  /// `pawlog-yyyy-MM-dd-HHmm.gpx` — 현지 시작 시각 기준.
  static String fileName(DateTime startedAt) =>
      'pawlog-${DateFormat('yyyy-MM-dd-HHmm').format(startedAt.toLocal())}.gpx';

  /// UTC ISO-8601, 초 단위로 자르고 `Z` 를 붙인다.
  static String _time(DateTime t) {
    final iso = t.toUtc().toIso8601String();
    return '${iso.substring(0, 19)}Z';
  }

  static String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
