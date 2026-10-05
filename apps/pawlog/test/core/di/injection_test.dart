import 'package:core/core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawlog/core/di/injection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // preResolve 되는 플랫폼 의존(문서 디렉터리 · SharedPreferences)만 흉내 낸다.
  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  const prefs = MethodChannel('plugins.flutter.io/shared_preferences');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger
      ..setMockMethodCallHandler(pathProvider, (_) async => '/tmp/pawlog')
      ..setMockMethodCallHandler(prefs, (_) async => <String, Object>{});
  });
  tearDown(() async {
    messenger
      ..setMockMethodCallHandler(pathProvider, null)
      ..setMockMethodCallHandler(prefs, null);
    await getIt.reset();
  });

  test('TileProvider 는 지도마다 새 인스턴스다 — TileLayer 가 dispose 하기 때문', () async {
    await configureDependencies();

    final first = getIt<TileProvider>();
    // 첫 지도가 사라지며 TileLayer 가 provider 를 dispose 한다.
    first.dispose();
    final second = getIt<TileProvider>();

    expect(identical(first, second), isFalse);
  });
}
