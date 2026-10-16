import 'dart:convert';

import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/domain/backup/entity/backup_data.dart';
import 'package:pawlog/domain/backup/policy/backup_codec.dart';
import 'package:pawlog/domain/dog/entity/dog.dart';
import 'package:pawlog/domain/walk/entity/geo_point.dart';
import 'package:pawlog/domain/walk/entity/walk.dart';
import 'package:pawlog/domain/walk/entity/walk_photo.dart';
import 'package:pawlog/domain/walk/entity/walk_track_point.dart';
import 'package:pawlog/domain/walk/policy/route_preview.dart';

final _exportedAt = DateTime.utc(2026, 10, 17, 3);
// 현지 시각으로 만든 값 — UTC 로 쓰고 같은 순간으로 돌아와야 한다.
final _t0 = DateTime(2026, 10, 3, 9);
final _t1 = DateTime(2026, 10, 3, 9, 30, 15, 250);

final _kong = Dog(
  id: 'd1',
  name: '콩이',
  birthday: DateTime(2020, 5, 1),
  photoPath: 'dogs/ab.jpg',
  createdAt: _t0,
  updatedAt: _t1,
);
final _bori = Dog(
  id: 'd2',
  name: '보리',
  breed: '푸들',
  createdAt: _t0,
  updatedAt: _t0,
);

List<WalkTrackPoint> _points(int n) => [
  for (var i = 0; i < n; i++)
    WalkTrackPoint(
      point: GeoPoint(lat: 37.5 + i / 10000, lng: 127.0 + i / 10000),
      recordedAt: _t0.add(Duration(seconds: i)),
      accuracy: i.isEven ? 5.0 : null,
    ),
];

BackupData _sample() {
  final points1 = _points(100);
  return BackupData(
    exportedAt: _exportedAt,
    dogs: [_kong, _bori],
    walks: [
      BackupWalk(
        walk: Walk(
          id: 'w1',
          startedAt: _t0,
          endedAt: _t1,
          duration: const Duration(minutes: 30, seconds: 15),
          distanceMeters: 1200.5,
          memo: '공원',
          dogs: [_kong, _bori],
          photos: const [
            WalkPhoto(id: 'p1', path: 'walks/w1/cd.jpg', position: 0),
            WalkPhoto(id: 'p2', path: 'walks/w1/ef.jpg', position: 1),
          ],
          previewPoints: RoutePreview.downsample(points1),
          createdAt: _t1,
          updatedAt: _t1,
        ),
        points: points1,
      ),
      BackupWalk(
        walk: Walk(
          id: 'w2',
          startedAt: _t0,
          endedAt: _t1,
          duration: const Duration(minutes: 1),
          distanceMeters: 0,
          dogs: [_bori],
          photos: const [],
          previewPoints: const [],
          createdAt: _t0,
          updatedAt: _t0,
        ),
        points: const [],
      ),
    ],
  );
}

BackupData _decodeOk(String json) => switch (BackupCodec.decode(json)) {
  Ok(:final value) => value,
  Err(:final failure) => fail('Err: $failure'),
};

void _expectSameDog(Dog actual, Dog expected) {
  expect(actual.id, expected.id);
  expect(actual.name, expected.name);
  expect(actual.breed, expected.breed);
  expect(actual.birthday, expected.birthday);
  expect(actual.photoPath, expected.photoPath);
  expect(actual.createdAt.isAtSameMomentAs(expected.createdAt), isTrue);
  expect(actual.updatedAt.isAtSameMomentAs(expected.updatedAt), isTrue);
}

void _expectSameWalk(BackupWalk actual, BackupWalk expected) {
  final a = actual.walk;
  final e = expected.walk;
  expect(a.id, e.id);
  expect(a.startedAt.isAtSameMomentAs(e.startedAt), isTrue);
  expect(a.endedAt.isAtSameMomentAs(e.endedAt), isTrue);
  expect(a.duration, e.duration);
  expect(a.distanceMeters, e.distanceMeters);
  expect(a.memo, e.memo);
  expect(a.dogs.map((d) => d.id), e.dogs.map((d) => d.id));
  expect(a.photos, e.photos);
  expect(a.previewPoints, e.previewPoints);
  expect(a.createdAt.isAtSameMomentAs(e.createdAt), isTrue);
  expect(a.updatedAt.isAtSameMomentAs(e.updatedAt), isTrue);
  expect(actual.points.length, expected.points.length);
  for (var i = 0; i < actual.points.length; i++) {
    expect(actual.points[i].point, expected.points[i].point);
    expect(actual.points[i].accuracy, expected.points[i].accuracy);
    expect(
      actual.points[i].recordedAt.isAtSameMomentAs(
        expected.points[i].recordedAt,
      ),
      isTrue,
    );
  }
}

Map<String, dynamic> _sampleJson() =>
    jsonDecode(BackupCodec.encode(_sample())) as Map<String, dynamic>;

void _expectInvalid(String json) {
  final result = BackupCodec.decode(json);
  expect(result, isA<Err<BackupData>>());
  expect(
    (result as Err<BackupData>).failure,
    isA<ValidationFailure>().having(
      (f) => f.failureCode,
      'failureCode',
      FailureCode.invalidData,
    ),
  );
}

void main() {
  test('왕복하면 같은 값으로 돌아온다', () {
    final original = _sample();

    final decoded = _decodeOk(BackupCodec.encode(original));

    expect(decoded.exportedAt.isAtSameMomentAs(original.exportedAt), isTrue);
    expect(decoded.dogs.length, 2);
    _expectSameDog(decoded.dogs[0], _kong);
    _expectSameDog(decoded.dogs[1], _bori);
    expect(decoded.walks.length, 2);
    _expectSameWalk(decoded.walks[0], original.walks[0]);
    _expectSameWalk(decoded.walks[1], original.walks[1]);
    // walk.dogs 는 같은 백업의 dogs 에서 채운 값이다
    _expectSameDog(decoded.walks[0].walk.dogs[0], _kong);
  });

  test('형식 머리 · 시각은 UTC · birthday 는 날짜만 · previewPoints 는 싣지 않는다', () {
    final json = _sampleJson();

    expect(json['format'], 'pawlog-backup');
    expect(json['version'], 1);
    expect(json['exportedAt'], '2026-10-17T03:00:00.000Z');
    final dogs = json['dogs'] as List<dynamic>;
    final kong = dogs[0] as Map<String, dynamic>;
    expect(kong['birthday'], '2020-05-01');
    expect(kong['createdAt'], _t0.toUtc().toIso8601String());
    expect((kong['createdAt'] as String).endsWith('Z'), isTrue);
    expect((dogs[1] as Map<String, dynamic>)['birthday'], isNull);
    final w1 = (json['walks'] as List<dynamic>)[0] as Map<String, dynamic>;
    expect(w1['durationSeconds'], 1815);
    expect(w1['dogIds'], ['d1', 'd2']);
    expect(w1.containsKey('previewPoints'), isFalse);
    final p0 = (w1['points'] as List<dynamic>)[0] as Map<String, dynamic>;
    expect(p0['lat'], 37.5);
    expect(p0['lng'], 127.0);
    expect((p0['recordedAt'] as String).endsWith('Z'), isTrue);
    expect(p0['accuracy'], 5.0);
    final w2 = (json['walks'] as List<dynamic>)[1] as Map<String, dynamic>;
    expect(w2['memo'], isNull);
  });

  test('birthday 는 현지 날짜로 돌아온다', () {
    final decoded = _decodeOk(BackupCodec.encode(_sample()));

    final birthday = decoded.dogs[0].birthday!;
    expect(birthday, DateTime(2020, 5, 1));
    expect(birthday.isUtc, isFalse);
  });

  test('다른 시간대 오프셋으로 적힌 시각도 같은 순간으로 읽는다', () {
    final json = _sampleJson();
    (json['walks'] as List<dynamic>)[0]['startedAt'] =
        '2026-10-03T09:00:00.000+09:00';

    final decoded = _decodeOk(jsonEncode(json));

    expect(
      decoded.walks[0].walk.startedAt.isAtSameMomentAs(
        DateTime.utc(2026, 10, 3, 0),
      ),
      isTrue,
    );
  });

  test('previewPoints 는 점에서 다시 만든다', () {
    final json = _sampleJson();

    final decoded = _decodeOk(jsonEncode(json));

    final walk = decoded.walks[0];
    expect(walk.walk.previewPoints, RoutePreview.downsample(walk.points));
    expect(walk.walk.previewPoints.length, RoutePreview.maxPoints);
    expect(decoded.walks[1].walk.previewPoints, isEmpty);
  });

  test('version 이 1.0 으로 적혀도 읽는다', () {
    final json = _sampleJson()..['version'] = 1.0;

    expect(BackupCodec.decode(jsonEncode(json)), isA<Ok<BackupData>>());
  });

  group('읽을 수 없으면 Err(validation · invalidData)', () {
    test('깨진 json', () => _expectInvalid('{"format": "pawlog-backup", '));

    test('최상위가 객체가 아님', () => _expectInvalid('[1, 2]'));

    test('다른 format', () {
      _expectInvalid(jsonEncode(_sampleJson()..['format'] = 'other'));
    });

    test('version 2', () {
      _expectInvalid(jsonEncode(_sampleJson()..['version'] = 2));
    });

    test('version 없음', () {
      _expectInvalid(jsonEncode(_sampleJson()..remove('version')));
    });

    test('exportedAt 없음', () {
      _expectInvalid(jsonEncode(_sampleJson()..remove('exportedAt')));
    });

    test('반려견 name 없음', () {
      final json = _sampleJson();
      ((json['dogs'] as List<dynamic>)[0] as Map<String, dynamic>).remove(
        'name',
      );
      _expectInvalid(jsonEncode(json));
    });

    test('산책 startedAt 이 시각이 아님', () {
      final json = _sampleJson();
      (json['walks'] as List<dynamic>)[0]['startedAt'] = 'yesterday';
      _expectInvalid(jsonEncode(json));
    });

    test('점 lat 없음', () {
      final json = _sampleJson();
      final w1 = (json['walks'] as List<dynamic>)[0] as Map<String, dynamic>;
      ((w1['points'] as List<dynamic>)[0] as Map<String, dynamic>).remove(
        'lat',
      );
      _expectInvalid(jsonEncode(json));
    });

    test('사진 path 없음', () {
      final json = _sampleJson();
      final w1 = (json['walks'] as List<dynamic>)[0] as Map<String, dynamic>;
      ((w1['photos'] as List<dynamic>)[0] as Map<String, dynamic>).remove(
        'path',
      );
      _expectInvalid(jsonEncode(json));
    });

    test('birthday 가 날짜 형식이 아님', () {
      final json = _sampleJson();
      (json['dogs'] as List<dynamic>)[0]['birthday'] = '2020/05/01';
      _expectInvalid(jsonEncode(json));
    });

    test('없는 날짜 birthday', () {
      final json = _sampleJson();
      (json['dogs'] as List<dynamic>)[0]['birthday'] = '2021-02-30';
      _expectInvalid(jsonEncode(json));
    });

    test('시간대 없는 시각', () {
      final json = _sampleJson();
      (json['walks'] as List<dynamic>)[0]['startedAt'] =
          '2026-10-03T09:00:00.000';
      _expectInvalid(jsonEncode(json));
    });

    test('walks 가 목록이 아님', () {
      _expectInvalid(jsonEncode(_sampleJson()..['walks'] = {'w1': 1}));
    });

    test('백업에 없는 dogId', () {
      final json = _sampleJson();
      (json['walks'] as List<dynamic>)[1]['dogIds'] = ['d1', 'ghost'];
      _expectInvalid(jsonEncode(json));
    });
  });
}
