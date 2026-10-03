import 'package:core/core.dart';
import 'package:drift/native.dart';
import 'package:feature_walk/feature_walk.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

Dog named(String id, String name) => Dog(
  id: id,
  name: name,
  birthday: DateTime(2020, 3, 5),
  createdAt: t0,
  updatedAt: t0,
);

List<Dog> _ok(Result<List<Dog>> r) => (r as Ok<List<Dog>>).value;

void main() {
  late WalkDatabase db;
  late DriftDogRepository repository;

  setUp(() {
    db = WalkDatabase(NativeDatabase.memory());
    repository = DriftDogRepository(db);
  });
  tearDown(() => db.close());

  test('저장 후 이름순으로 watch 된다', () async {
    await repository.upsert(named('1', '하늘'));
    await repository.upsert(named('2', '가을'));

    final result = await repository.watchAll().first;

    expect(_ok(result).map((d) => d.name), ['가을', '하늘']);
    expect(_ok(result).first.birthday, DateTime(2020, 3, 5));
  });

  test('수정이 스트림에 반영된다', () async {
    await repository.upsert(named('1', '콩이'));
    final emissions = <List<String>>[];
    final sub = repository.watchAll().listen(
      (r) => emissions.add(_ok(r).map((d) => d.name).toList()),
    );
    await pumpEventQueue();

    await repository.upsert(named('1', '두부'));
    await pumpEventQueue();
    await sub.cancel();

    expect(emissions.last, ['두부']);
  });

  test('삭제하면 사라진다', () async {
    await repository.upsert(named('1', '콩이'));

    await repository.delete('1');

    expect(_ok(await repository.getAll()), isEmpty);
  });

  test('findById 는 없으면 null', () async {
    await repository.upsert(named('1', '콩이'));

    expect(((await repository.findById('1')) as Ok<Dog?>).value?.name, '콩이');
    expect(((await repository.findById('x')) as Ok<Dog?>).value, isNull);
  });
}
