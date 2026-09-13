import 'dart:convert';
import 'package:core/core.dart';
import 'package:feature_commute/feature_commute.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.value);

  final String value;
  int loadCount = 0;

  @override
  Future<ByteData> load(String key) async {
    loadCount++;
    final bytes = Uint8List.fromList(utf8.encode(value));
    return ByteData.sublistView(bytes);
  }
}

const _json = '''
[
  {"id":"0739","name":"장승 배기","lines":["7"],"lat":37.5048,"lng":126.9391},
  {"id":"0222","name":"GangNam","lines":["2","신분당"],"lat":37.4979,"lng":127.0276}
]
''';

void main() {
  late _MemoryAssetBundle bundle;
  late AssetStationRepository repository;

  setUp(() {
    bundle = _MemoryAssetBundle(_json);
    repository = AssetStationRepository.withBundle(bundle);
  });

  test('공백을 제거한 부분 일치로 검색한다', () async {
    final result = await repository.search('승 배');

    expect((result as Ok<List<Station>>).value.single.id, '0739');
  });

  test('영문 역 이름은 대소문자를 무시한다', () async {
    final result = await repository.search('gAnGn');

    expect((result as Ok<List<Station>>).value.single.id, '0222');
  });

  test('빈 질의는 목록을 읽지 않고 빈 결과를 반환한다', () async {
    final result = await repository.search('   ');

    expect((result as Ok<List<Station>>).value, isEmpty);
    expect(bundle.loadCount, 0);
  });

  test('없는 id는 null이고 자산은 한 번만 읽는다', () async {
    final first = await repository.findById('missing');
    final second = await repository.findById('0222');

    expect((first as Ok<Station?>).value, isNull);
    expect((second as Ok<Station?>).value?.name, 'GangNam');
    expect(bundle.loadCount, 1);
  });
}
